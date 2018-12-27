# frozen_string_literal: true

# This service downloads and links lfs objects from a remote URL
module Projects
  module LfsPointers
    class LfsDownloadService < BaseService
      VALID_PROTOCOLS = %w[http https].freeze

      # rubocop: disable CodeReuse/ActiveRecord
      def execute(oid, url)
        return unless project&.lfs_enabled? && oid.present? && url.present?

        return if LfsObject.exists?(oid: oid)

        sanitized_uri = sanitize_url!(url)

        with_tmp_file(oid) do |file|
          download_and_save_file(file, sanitized_uri)
          lfs_object = LfsObject.new(oid: oid, size: file.size, file: file)

          project.all_lfs_objects << lfs_object
        end
      rescue Gitlab::UrlBlocker::BlockedUrlError => e
        Rails.logger.error("LFS file with oid #{oid} couldn't be downloaded: #{e.message}")
      rescue StandardError => e
        Rails.logger.error("LFS file with oid #{oid} couldn't be downloaded from #{sanitized_uri.sanitized_url}: #{e.message}")
      end
      # rubocop: enable CodeReuse/ActiveRecord

      private

      def sanitize_url!(url)
        Gitlab::UrlSanitizer.new(url).tap do |sanitized_uri|
          # Just validate that HTTP/HTTPS protocols are used. The
          # subsequent Gitlab::HTTP.get call will do network checks
          # based on the settings.
          Gitlab::UrlBlocker.validate!(sanitized_uri.sanitized_url,
                                       protocols: VALID_PROTOCOLS)
        end
      end

      def download_and_save_file(file, sanitized_uri)
        response = Gitlab::HTTP.get(sanitized_uri.sanitized_url, headers(sanitized_uri)) do |fragment|
          file.write(fragment)
        end

        raise StandardError, "Received error code #{response.code}" unless response.success?
      end

      def headers(sanitized_uri)
        query_options.tap do |headers|
          credentials = sanitized_uri.credentials

          if credentials[:user].present? || credentials[:password].present?
            # Using authentication headers in the request
            headers[:http_basic_authentication] = [credentials[:user], credentials[:password]]
          end
        end
      end

      def query_options
        { stream_body: true }
      end

      def with_tmp_file(oid)
        create_tmp_storage_dir

        File.open(File.join(tmp_storage_dir, oid), 'wb') { |file| yield file }
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
    end
  end
end
