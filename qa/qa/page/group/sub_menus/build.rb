# frozen_string_literal: true

module QA
  module Page
    module Group
      module SubMenus
        module Build
          extend QA::Page::PageConcern

          def go_to_runners
            open_build_submenu("Runners")
          end

          private

          def open_build_submenu(sub_menu)
            open_submenu("Build", sub_menu)
          end
        end
      end
    end
  end
end
