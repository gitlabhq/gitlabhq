# frozen_string_literal: true

# This service downloads and links lfs objects from a remote URL
module Projects
  module LfsPointers
    class LfsDownloadService < BaseService
      SizeError = Class.new(StandardError)
      OidError = Class.new(StandardError)
      ResponseError = Class.new(StandardError)

      LARGE_FILE_SIZE = 1.megabyte

      attr_reader :lfs_download_object

      delegate :oid, :size, :credentials, :sanitized_url, :headers, to: :lfs_download_object, prefix: :lfs

      def initialize(project, lfs_download_object)
        super(project)

        @lfs_download_object = lfs_download_object
      end

      def execute
        return unless project&.lfs_enabled? && lfs_download_object
        return error("LFS file with oid #{lfs_oid} has invalid attributes") unless lfs_download_object.valid?
        return link_existing_lfs_object! if lfs_size > LARGE_FILE_SIZE && lfs_object

        wrap_download_errors do
          download_lfs_file!
        end
      end

      private

      def wrap_download_errors(&block)
        yield
      rescue SizeError, OidError, ResponseError, StandardError => e
        error("LFS file with oid #{lfs_oid} couldn't be downloaded from #{lfs_sanitized_url}: #{e.message}")
      end

      def download_lfs_file!
        with_tmp_file do |tmp_file|
          download_and_save_file!(tmp_file)

          project.lfs_objects << find_or_create_lfs_object(tmp_file)

          success
        end
      end

      def find_or_create_lfs_object(tmp_file)
        lfs_obj = LfsObject.safe_find_or_create_by!(
          oid: lfs_oid,
          size: lfs_size
        )

        lfs_obj.update!(file: tmp_file) unless lfs_obj.file.file

        lfs_obj
      end

      def download_and_save_file!(file)
        digester = Digest::SHA256.new
        fetch_file do |fragment|
          if digest_fragment?(fragment)
            digester << fragment
            file.write(fragment)
          end

          raise_size_error! if file.size > lfs_size
        end

        raise_size_error! if file.size != lfs_size
        raise_oid_error! if digester.hexdigest != lfs_oid
      end

      def digest_fragment?(fragment)
        fragment.http_response.is_a?(Net::HTTPSuccess)
      end

      def download_options
        # Set accept-encoding to identity to request web servers not to send a compressed response to avoid using too
        # much memory to decompress the file. In case the response is encoded, the response size will be limited by
        # `max_http_decompressed_size application` application setting.
        http_options = { headers: lfs_headers.merge('accept-encoding' => 'identity'), stream_body: true }

        return http_options if lfs_download_object.has_authorization_header?

        http_options.tap do |options|
          if lfs_credentials[:user].present? || lfs_credentials[:password].present?
            # Using authentication headers in the request
            options[:basic_auth] = { username: lfs_credentials[:user], password: lfs_credentials[:password] }
          end
        end
      end

      def fetch_file(&block)
        attempts ||= 1
        response = Gitlab::HTTP.get(lfs_sanitized_url, download_options, &block)

        raise ResponseError, "Received error code #{response.code}" unless response.success?
      rescue Net::OpenTimeout
        raise if attempts >= 3

        attempts += 1
        retry
      end

      def with_tmp_file
        create_tmp_storage_dir

        File.open(tmp_filename, 'wb') do |file|
          yield file
        rescue StandardError => e
          # If the lfs file is successfully downloaded it will be removed
          # when it is added to the project's lfs files.
          # Nevertheless if any exception raises the file would remain
          # in the file system. Here we ensure to remove it
          FileUtils.rm_f(file)

          raise e
        end
      end

      def tmp_filename
        File.join(tmp_storage_dir, lfs_oid)
      end

      def create_tmp_storage_dir
        FileUtils.makedirs(tmp_storage_dir)
      end

      def tmp_storage_dir
        @tmp_storage_dir ||= File.join(storage_dir, 'tmp', 'download')
      end

      def storage_dir
        @storage_dir ||= Gitlab.config.lfs.storage_path
      end

      def raise_size_error!
        raise SizeError, 'Size mistmatch'
      end

      def raise_oid_error!
        raise OidError, 'Oid mismatch'
      end

      def error(message, http_status = nil)
        log_error(message)

        super
      end

      def lfs_object
        @lfs_object ||= LfsObject.find_by_oid(lfs_oid)
      end

      def link_existing_lfs_object!
        existing_file = lfs_object.file.open
        buffer_size = 0
        result = fetch_file do |fragment|
          unless fragment == existing_file.read(fragment.size)
            break error("LFS file with oid #{lfs_oid} cannot be linked with an existing LFS object")
          end

          buffer_size += fragment.size
          break success if buffer_size > LARGE_FILE_SIZE
        end

        project.lfs_objects << lfs_object

        result
      ensure
        existing_file&.close
      end
    end
  end
end
