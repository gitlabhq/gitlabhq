# frozen_string_literal: true

module BulkImports # rubocop:disable Gitlab/BoundedContexts -- will be moved with all other pipelines
  module Common
    module Pipelines
      class MaxIidsPipeline
        include Pipeline

        file_extraction_pipeline!

        relation_name BulkImports::FileTransfer::BaseConfig::MAX_IIDS_RELATION

        extractor ::BulkImports::Common::Extractors::JsonExtractor, relation: relation

        ALLOWED_KEYS = ::Gitlab::Import::IidPreallocator.trackable_resources.keys.to_set.freeze
        MAX_VALID_IID = ::Gitlab::Import::IidPreallocator::MAX_VALID_IID

        def transform(_context, data)
          return unless data.is_a?(Hash)
          return if data.empty?

          data.each_with_object({}) do |(key, value), result|
            sym_key = key.to_sym
            next unless ALLOWED_KEYS.include?(sym_key)
            next unless value.is_a?(Integer) && value > 0 && value <= MAX_VALID_IID

            result[sym_key] = value
          end
        end

        def load(_context, data)
          return unless data.present?

          ::Gitlab::Import::IidPreallocator.new(portable, data).execute
        end

        def after_run(_context)
          extractor.remove_tmpdir
        end
      end
    end
  end
end
