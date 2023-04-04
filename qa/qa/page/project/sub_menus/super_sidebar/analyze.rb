# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module SuperSidebar
          module Analyze
            extend QA::Page::PageConcern

            def self.included(base)
              super

              base.class_eval do
                include QA::Page::Project::SubMenus::SuperSidebar::Common
              end
            end

            def go_to_value_stream_analytics
              open_analyze_submenu('Value stream analytics')
            end

            def go_to_contributor_statistics
              open_analyze_submenu('Contributor statistics')
            end

            def go_to_ci_cd_analytics
              open_analyze_submenu('CI/CD analytics')
            end

            def go_to_repository_analytics
              open_analyze_submenu('Repository analytics')
            end

            private

            def open_analyze_submenu(sub_menu)
              open_submenu('Analyze', '#analyze', sub_menu)
            end
          end
        end
      end
    end
  end
end
