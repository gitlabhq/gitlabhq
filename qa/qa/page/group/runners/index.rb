# frozen_string_literal: true

module QA
  module Page
    module Group
      module Runners
        class Index < Page::Base
          view "app/assets/javascripts/ci/runner/group_runners/group_runners_app.vue" do
            element 'new-group-runner-button'
          end

          # Returns total count of all runner types
          #
          # @return [Integer]
          def count_all_runners
            find_element("runner-count-all").text.to_i
          end

          # Returns total count of group runner types
          #
          # @return [Integer]
          def count_group_runners
            find_element("runner-count-group").text.to_i
          end

          # Returns total count of project runner types
          #
          # @return [Integer]
          def count_project_runners
            find_element("runner-count-project").text.to_i
          end

          # Returns count of online runners
          #
          # @return [Integer]
          def count_online_runners
            within_element("runner-stats-online") do
              find_element("non-animated-value").text.to_i
            end
          end
        end
      end
    end
  end
end
