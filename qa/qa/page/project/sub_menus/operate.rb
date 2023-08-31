# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Operate
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.class_eval do
              include QA::Page::SubMenus::Operate
            end
          end

          def go_to_infrastructure_registry
            open_operate_submenu('Terraform modules')
          end

          def go_to_kubernetes_clusters
            open_operate_submenu('Kubernetes clusters')
          end

          def go_to_terraform
            open_operate_submenu('Terraform states')
          end

          private

          def open_operate_submenu(sub_menu)
            open_submenu('Operate', sub_menu)
          end
        end
      end
    end
  end
end
