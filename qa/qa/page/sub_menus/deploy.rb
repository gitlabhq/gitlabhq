# frozen_string_literal: true

module QA
  module Page
    module SubMenus
      module Deploy
        extend QA::Page::PageConcern

        def go_to_package_registry
          open_deploy_submenu("Package Registry")
        end

        def go_to_container_registry
          open_deploy_submenu('Container Registry')
        end

        def go_to_pages_settings
          open_deploy_submenu('Pages')
        end

        private

        def open_deploy_submenu(sub_menu)
          open_submenu("Deploy", sub_menu)
        end
      end
    end
  end
end
