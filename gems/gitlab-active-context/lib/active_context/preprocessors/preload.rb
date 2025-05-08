# frozen_string_literal: true

module ActiveContext
  module Preprocessors
    module Preload
      extend ActiveSupport::Concern

      PreloadError = Class.new(StandardError)

      BATCH_SIZE = 1000

      class_methods do
        def preload(refs)
          return { successful: [], failed: [] } if refs.empty?

          with_batch_handling(refs) do
            unless model_klass.respond_to?(:preload_indexing_data)
              raise PreloadError, "#{self} class should implement :preload_indexing_data method"
            end

            refs.each_slice(BATCH_SIZE) do |batch|
              preload_batch(batch)
            end

            refs
          end
        end

        def preload_batch(batch)
          ids = batch.map(&:identifier)
          records = model_klass.id_in(ids).preload_indexing_data
          records_by_id = records.index_by(&:id)

          with_per_ref_handling(batch) do |ref|
            record = records_by_id[ref.identifier.to_i]

            raise PreloadError, "Record not found for identifier: #{ref.identifier}" unless record

            ref.database_record = record
          end
        end
      end
    end
  end
end
