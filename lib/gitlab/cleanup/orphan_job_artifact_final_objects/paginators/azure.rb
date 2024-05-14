# frozen_string_literal: true

module Gitlab
  module Cleanup
    module OrphanJobArtifactFinalObjects
      module Paginators
        class Azure < BasePaginator
          def page_marker_filter_key
            :marker
          end

          def max_results_filter_key
            :max_results
          end

          def last_page?(batch)
            batch.next_marker.nil?
          end

          def get_next_marker(batch)
            batch.next_marker
          end
        end
      end
    end
  end
end
