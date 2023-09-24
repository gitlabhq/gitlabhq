# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Build
          extend QA::Page::PageConcern

          def go_to_pipelines
            open_build_submenu('Pipelines')
          end

          def go_to_pipeline_editor
            open_build_submenu('Pipeline editor')
          end

          def go_to_jobs
            open_build_submenu('Jobs')
          end

          def go_to_schedules
            open_build_submenu('Pipeline schedules')
          end

          def go_to_artifacts
            open_build_submenu('Artifacts')
          end

          private

          def open_build_submenu(sub_menu)
            open_submenu('Build', sub_menu)
          end
        end
      end
    end
  end
end
