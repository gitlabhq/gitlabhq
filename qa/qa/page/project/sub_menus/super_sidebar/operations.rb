# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module SuperSidebar
          module Operations
            extend QA::Page::PageConcern

            def self.included(base)
              super

              base.class_eval do
                include QA::Page::Project::SubMenus::SuperSidebar::Common
              end
            end

            def go_to_environments
              open_operations_submenu('Environments')
            end

            def go_to_feature_flags
              open_operations_submenu('Feature flags')
            end

            def go_to_releases
              open_operations_submenu('Releases')
            end

            def go_to_package_registry
              open_operations_submenu('Package Registry')
            end

            def go_to_infrastructure_registry
              open_operations_submenu('Infrastructure Registry')
            end

            def go_to_kubernetes_clusters
              open_operations_submenu('Kubernetes clusters')
            end

            def go_to_terraform
              open_operations_submenu('Terraform')
            end

            private

            def open_operations_submenu(sub_menu)
              open_submenu("Operations", "#operations", sub_menu)
            end
          end
        end
      end
    end
  end
end
