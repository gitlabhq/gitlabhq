# frozen_string_literal: true

# This service downloads and links lfs objects from a remote URL
module Projects
  module LfsPointers
    class LfsDownloadService < BaseService
      SizeError = Class.new(StandardError)
      OidError = Class.new(StandardError)

      attr_reader :lfs_download_object
      delegate :oid, :size, :credentials, :sanitized_url, to: :lfs_download_object, prefix: :lfs

      def initialize(project, lfs_download_object)
        super(project)

        @lfs_download_object = lfs_download_object
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def execute
        return unless project&.lfs_enabled? && lfs_download_object
        return error("LFS file with oid #{lfs_oid} has invalid attributes") unless lfs_download_object.valid?
        return if LfsObject.exists?(oid: lfs_oid)

        wrap_download_errors do
          download_lfs_file!
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      def wrap_download_errors(&block)
        yield
      rescue SizeError, OidError, StandardError => e
        error("LFS file with oid #{lfs_oid} could't be downloaded from #{lfs_sanitized_url}: #{e.message}")
      end

      def download_lfs_file!
        with_tmp_file do |tmp_file|
          download_and_save_file!(tmp_file)
          project.all_lfs_objects << LfsObject.new(oid: lfs_oid,
                                                   size: lfs_size,
                                                   file: tmp_file)

          success
        end
      end

      def download_and_save_file!(file)
        digester = Digest::SHA256.new
        response = Gitlab::HTTP.get(lfs_sanitized_url, download_headers) do |fragment|
          digester << fragment
          file.write(fragment)

          raise_size_error! if file.size > lfs_size
        end

        raise StandardError, "Received error code #{response.code}" unless response.success?

        raise_size_error! if file.size != lfs_size
        raise_oid_error! if digester.hexdigest != lfs_oid
      end

      def download_headers
        { stream_body: true }.tap do |headers|
          if lfs_credentials[:user].present? || lfs_credentials[:password].present?
            # Using authentication headers in the request
            headers[:basic_auth] = { username: lfs_credentials[:user], password: lfs_credentials[:password] }
          end
        end
      end

      def with_tmp_file
        create_tmp_storage_dir

        File.open(tmp_filename, 'wb') do |file|
          yield file
        rescue StandardError => e
          # If the lfs file is successfully downloaded it will be removed
          # when it is added to the project's lfs files.
          # Nevertheless if any excetion raises the file would remain
          # in the file system. Here we ensure to remove it
          File.unlink(file) if File.exist?(file)

          raise e
        end
      end

      def tmp_filename
        File.join(tmp_storage_dir, lfs_oid)
      end

      def create_tmp_storage_dir
        FileUtils.makedirs(tmp_storage_dir) unless Dir.exist?(tmp_storage_dir)
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
    end
  end
end
