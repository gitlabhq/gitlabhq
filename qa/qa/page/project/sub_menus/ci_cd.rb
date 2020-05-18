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

              view 'app/views/layouts/nav/sidebar/_project.html.haml' do
                element :link_pipelines
              end
            end
          end

          def click_ci_cd_pipelines
            within_sidebar do
              click_element :link_pipelines
            end
          end
        end
      end
    end
  end
end
