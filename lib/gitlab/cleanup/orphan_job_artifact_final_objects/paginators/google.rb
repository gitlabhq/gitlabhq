# frozen_string_literal: true

module Gitlab
  module Cleanup
    module OrphanJobArtifactFinalObjects
      module Paginators
        class Google < BasePaginator
          def filters(marker)
            pattern = [bucket_prefix, '*/*/*/@final/**'].compact.join('/')
            super.merge(match_glob: pattern)
          end

          def page_marker_filter_key
            :page_token
          end

          def max_results_filter_key
            :max_results
          end

          def last_page?(batch)
            batch.next_page_token.nil?
          end

          def get_next_marker(batch)
            batch.next_page_token
          end
        end
      end
    end
  end
end
