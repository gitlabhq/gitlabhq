# frozen_string_literal: true

module Packages
  module Maven
    module Metadata
      class AppendPackageFileService
        XML_CONTENT_TYPE = 'application/xml'
        DEFAULT_CONTENT_TYPE = 'application/octet-stream'

        MD5_FILE_NAME = "#{Metadata.filename}.md5"
        SHA1_FILE_NAME = "#{Metadata.filename}.sha1"
        SHA256_FILE_NAME = "#{Metadata.filename}.sha256"
        SHA512_FILE_NAME = "#{Metadata.filename}.sha512"

        def initialize(package:, metadata_content:)
          @package = package
          @metadata_content = metadata_content
        end

        def execute
          return ServiceResponse.error(message: 'package is not set') unless @package
          return ServiceResponse.error(message: 'metadata content is not set') unless @metadata_content

          file_md5 = digest_from(@metadata_content, :md5)
          file_sha1 = digest_from(@metadata_content, :sha1)
          file_sha256 = digest_from(@metadata_content, :sha256)
          file_sha512 = digest_from(@metadata_content, :sha512)

          @package.transaction do
            append_metadata_file(
              content: @metadata_content,
              file_name: Metadata.filename,
              content_type: XML_CONTENT_TYPE,
              sha1: file_sha1,
              md5: file_md5,
              sha256: file_sha256
            )

            append_metadata_file(content: file_md5, file_name: MD5_FILE_NAME) unless Gitlab::FIPS.enabled?
            append_metadata_file(content: file_sha1, file_name: SHA1_FILE_NAME)
            append_metadata_file(content: file_sha256, file_name: SHA256_FILE_NAME)
            append_metadata_file(content: file_sha512, file_name: SHA512_FILE_NAME)
          end

          ServiceResponse.success(message: 'New metadata package file created')
        end

        private

        def append_metadata_file(content:, file_name:, content_type: DEFAULT_CONTENT_TYPE, sha1: nil, md5: nil, sha256: nil)
          file_md5 = md5 || digest_from(content, :md5)
          file_sha1 = sha1 || digest_from(content, :sha1)
          file_sha256 = sha256 || digest_from(content, :sha256)

          file = CarrierWaveStringFile.new_file(
            file_content: content,
            filename: file_name,
            content_type: content_type
          )

          ::Packages::CreatePackageFileService.new(
            @package,
            file: file,
            size: file.size,
            file_name: file_name,
            file_sha1: file_sha1,
            file_md5: file_md5,
            file_sha256: file_sha256
          ).execute
        end

        def digest_from(content, type)
          return if type == :md5 && Gitlab::FIPS.enabled?

          digest_class = case type
                         when :md5
                           Digest::MD5
                         when :sha1
                           Digest::SHA1
                         when :sha256
                           Digest::SHA256
                         when :sha512
                           Digest::SHA512
                         end
          digest_class.hexdigest(content)
        end
      end
    end
  end
end
