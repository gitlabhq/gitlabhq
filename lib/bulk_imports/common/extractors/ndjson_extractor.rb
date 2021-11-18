# frozen_string_literal: true

module BulkImports
  module Common
    module Extractors
      class NdjsonExtractor
        include Gitlab::ImportExport::CommandLineUtil
        include Gitlab::Utils::StrongMemoize

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
            relative_url: context.entity.relation_download_url_path(relation),
            dir: tmp_dir,
            filename: filename
          )
        end

        def decompression_service(tmp_dir)
          @decompression_service ||= BulkImports::FileDecompressionService.new(dir: tmp_dir, filename: filename)
        end

        def ndjson_reader(tmp_dir)
          @ndjson_reader ||= Gitlab::ImportExport::Json::NdjsonReader.new(tmp_dir)
        end
      end
    end
  end
end
