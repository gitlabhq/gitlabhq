# frozen_string_literal: true

module Gitlab
  module Cleanup
    module OrphanJobArtifactFinalObjects
      module Paginators
        class BasePaginator
          BATCH_SIZE = Rails.env.development? ? 5 : 1000

          def initialize(bucket_prefix: nil)
            @bucket_prefix = bucket_prefix
          end

          def filters(marker)
            {
              page_marker_filter_key => marker,
              max_results_filter_key => BATCH_SIZE,
              prefix: bucket_prefix
            }
          end

          def last_page?(batch)
            # Fog providers have different indicators of last page, so we want to delegate this
            # knowledge to the specific provider implementation.
            raise NotImplementedError, "Subclasses must define `last_page?(batch)` instance method"
          end

          def get_next_marker(batch)
            # Fog providers have different ways to get the next marker, so we want to delegate this
            # knowledge to the specific provider implementation.
            raise NotImplementedError, "Subclasses must define `get_next_marker(batch)` instance method"
          end

          private

          attr_reader :bucket_prefix

          def page_marker_filter_key
            raise NotImplementedError, "Subclasses must define `page_marker_key` instance method"
          end

          def max_results_filter_key
            raise NotImplementedError, "Subclasses must define `max_results_filter_key` instance method"
          end
        end
      end
    end
  end
end
