# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module SuperSidebar
          module CiCd
            extend QA::Page::PageConcern

            def self.included(base)
              super

              base.class_eval do
                include QA::Page::Project::SubMenus::SuperSidebar::Common
              end
            end

            def go_to_pipelines
              open_ci_cd_submenu('Pipelines')
            end

            def go_to_editor
              open_ci_cd_submenu('Editor')
            end

            def go_to_jobs
              open_ci_cd_submenu('Jobs')
            end

            def go_to_schedules
              open_ci_cd_submenu('Schedules')
            end

            private

            def open_ci_cd_submenu(sub_menu)
              open_submenu("CI/CD", "#ci-cd", sub_menu)
            end
          end
        end
      end
    end
  end
end
