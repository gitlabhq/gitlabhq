# frozen_string_literal: true

module ActiveContext
  module Preprocessors
    module Preload
      extend ActiveSupport::Concern

      IndexingError = Class.new(StandardError)

      BATCH_SIZE = 1000

      class_methods do
        def preload(refs)
          unless model_klass.respond_to?(:preload_indexing_data)
            raise IndexingError, "#{self} class should implement :preload_indexing_data method"
          end

          refs.each_slice(BATCH_SIZE) do |batch|
            preload_batch(batch)
          end

          refs
        rescue StandardError => e
          ::ActiveContext::Logger.exception(e)
          refs # continue even though refs are not preloaded
        end

        def preload_batch(batch)
          ids = batch.map(&:identifier)

          records = model_klass.id_in(ids).preload_indexing_data
          records_by_id = records.index_by(&:id)

          batch.each do |ref|
            ref.database_record = records_by_id[ref.identifier.to_i]
          end
        end
      end
    end
  end
end
