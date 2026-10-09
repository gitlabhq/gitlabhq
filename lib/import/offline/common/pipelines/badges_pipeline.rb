# frozen_string_literal: true

module Import
  module Offline
    module Common
      module Pipelines
        class BadgesPipeline < ::BulkImports::Common::Pipelines::BadgesPipeline
          file_extraction_pipeline!

          relation_name 'badges'

          extractor ::BulkImports::Common::Extractors::NdjsonExtractor, relation: relation

          # Pipeline class attributes are per-class, so retain the base badge transformers.
          def self.transformers
            superclass.transformers
          end

          # Unwraps the NDJSON record before applying the badge transformations.
          #
          # @param context [BulkImports::Pipeline::Context] the import context
          # @param data [Array] the badge record and its relation index
          # @return [Hash, nil] transformed badge attributes, or nil to skip the record
          def transform(context, data)
            badge, = data
            return unless badge

            # Offline badges are already split by relation, so the REST-only `kind` check is unnecessary.
            super(context, badge)
          end

          # Extracts badge records from the offline transfer file.
          #
          # @param context [BulkImports::Pipeline::Context] the import context
          # @return [BulkImports::Pipeline::ExtractedData] extracted badges
          def extract(context)
            file_extractor.extract(context)
          end

          # Removes the temporary files created while extracting badges.
          #
          # @param _context [BulkImports::Pipeline::ExtractedData] extracted data
          # @return [void]
          def after_run(_context)
            file_extractor.remove_tmpdir
          end

          private

          # Returns the NDJSON extractor configured for this pipeline's relation.
          #
          # @return [BulkImports::Common::Extractors::NdjsonExtractor] the extractor
          def file_extractor
            @file_extractor ||= instantiate(self.class.get_extractor)
          end
        end
      end
    end
  end
end
