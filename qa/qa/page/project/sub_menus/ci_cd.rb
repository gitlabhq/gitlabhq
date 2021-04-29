# frozen_string_literal: true

module QA
  module Page
    module Project
      module SubMenus
        module CiCd
          extend QA::Page::PageConcern

          def self.included(base)
            super

            base.class_eval do
              include QA::Page::Project::SubMenus::Common
            end
          end

          def click_ci_cd_pipelines
            within_sidebar do
              click_element(:sidebar_menu_link, menu_item: 'CI/CD')
            end
          end
        end
      end
    end
  end
end
