# frozen_string_literal: true

module BulkImports
  module Common
    module Extractors
      class JsonExtractor
        def initialize(relation:)
          @relation = relation
          @tmpdir = Dir.mktmpdir
        end

        def extract(context)
          download_service(context).execute
          decompression_service.execute

          attributes = ndjson_reader.consume_attributes(relation)

          BulkImports::Pipeline::ExtractedData.new(data: attributes)
        end

        def remove_tmpdir
          FileUtils.rm_rf(tmpdir)
        end

        private

        attr_reader :relation, :tmpdir

        def filename
          "#{relation}.json.gz"
        end

        def download_service(context)
          @download_service ||= BulkImports::FileDownloadService.new(
            configuration: context.configuration,
            relative_url: context.entity.relation_download_url_path(relation),
            tmpdir: tmpdir,
            filename: filename
          )
        end

        def decompression_service
          @decompression_service ||= BulkImports::FileDecompressionService.new(tmpdir: tmpdir, filename: filename)
        end

        def ndjson_reader
          @ndjson_reader ||= Gitlab::ImportExport::Json::NdjsonReader.new(tmpdir)
        end
      end
    end
  end
end
