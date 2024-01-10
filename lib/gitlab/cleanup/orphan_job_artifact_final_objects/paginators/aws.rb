# frozen_string_literal: true

module Gitlab
  module Cleanup
    module OrphanJobArtifactFinalObjects
      module Paginators
        class Aws < BasePaginator
          def page_marker_filter_key
            :marker
          end

          def max_results_filter_key
            :max_keys
          end

          def last_page?(batch)
            batch.empty?
          end

          def get_next_marker(batch)
            batch.last.key
          end
        end
      end
    end
  end
end
