# This service downloads and links lfs objects from a remote URL
module Projects
  module LfsPointers
    class LfsDownloadService < BaseService
      def execute(oid, url)
        return unless project&.lfs_enabled? && oid.present? && url.present?

        return if LfsObject.exists?(oid: oid)

        sanitized_uri = Gitlab::UrlSanitizer.new(url)

        with_tmp_file(oid) do |file|
          size = download_and_save_file(file, sanitized_uri)
          lfs_object = LfsObject.new(oid: oid, size: size, file: file)

          project.all_lfs_objects << lfs_object
        end
      rescue StandardError => e
        Rails.logger.error("LFS file with oid #{oid} could't be downloaded from #{sanitized_uri.sanitized_url}: #{e.message}")
      end

      private

      def download_and_save_file(file, sanitized_uri)
        IO.copy_stream(open(sanitized_uri.sanitized_url, headers(sanitized_uri)), file)
      end

      def headers(sanitized_uri)
        {}.tap do |headers|
          credentials = sanitized_uri.credentials

          if credentials[:user].present? || credentials[:password].present?
            # Using authentication headers in the request
            headers[:http_basic_authentication] = [credentials[:user], credentials[:password]]
          end
        end
      end

      def with_tmp_file(oid)
        create_tmp_storage_dir

        File.open(File.join(tmp_storage_dir, oid), 'w') { |file| yield file }
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
