# frozen_string_literal: true

module BulkImports
  module Common
    module Extractors
      class NdjsonExtractor
        include Gitlab::ImportExport::CommandLineUtil
        include Gitlab::Utils::StrongMemoize

        FILE_SIZE_LIMIT = 5.gigabytes
        ALLOWED_CONTENT_TYPES = %w(application/gzip application/octet-stream).freeze
        EXPORT_DOWNLOAD_URL_PATH = "/%{resource}/%{full_path}/export_relations/download?relation=%{relation}"

        def initialize(relation:)
          @relation = relation
          @tmp_dir = Dir.mktmpdir
        end

        def extract(context)
          download_service(tmp_dir, context).execute
          decompression_service(tmp_dir).execute
          relations = ndjson_reader(tmp_dir).consume_relation('', relation)

          BulkImports::Pipeline::ExtractedData.new(data: relations)
        end

        def remove_tmp_dir
          FileUtils.remove_entry(tmp_dir)
        end

        private

        attr_reader :relation, :tmp_dir

        def filename
          @filename ||= "#{relation}.ndjson.gz"
        end

        def download_service(tmp_dir, context)
          @download_service ||= BulkImports::FileDownloadService.new(
            configuration: context.configuration,
            relative_url: relative_resource_url(context),
            dir: tmp_dir,
            filename: filename,
            file_size_limit: FILE_SIZE_LIMIT,
            allowed_content_types: ALLOWED_CONTENT_TYPES
          )
        end

        def decompression_service(tmp_dir)
          @decompression_service ||= BulkImports::FileDecompressionService.new(
            dir: tmp_dir,
            filename: filename
          )
        end

        def ndjson_reader(tmp_dir)
          @ndjson_reader ||= Gitlab::ImportExport::Json::NdjsonReader.new(tmp_dir)
        end

        def relative_resource_url(context)
          strong_memoize(:relative_resource_url) do
            resource = context.portable.class.name.downcase.pluralize
            encoded_full_path = context.entity.encoded_source_full_path

            EXPORT_DOWNLOAD_URL_PATH % { resource: resource, full_path: encoded_full_path, relation: relation }
          end
        end
      end
    end
  end
end
