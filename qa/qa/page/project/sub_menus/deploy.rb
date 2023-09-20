# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module Deploy
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.class_eval do
              include QA::Page::SubMenus::SuperSidebar::Deploy
            end
          end

          def go_to_releases
            open_deploy_submenu("Releases")
          end

          def go_to_feature_flags
            open_deploy_submenu("Feature flags")
          end
        end
      end
    end
  end
end
