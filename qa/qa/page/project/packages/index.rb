# frozen_string_literal: true

module QA
  module Page
    module Project
      module Packages
        class Index < QA::Page::Base
          view 'app/assets/javascripts/packages/shared/components/package_list_row.vue' do
            element :package_row
            element :package_link
          end

          def click_package(name)
            click_element(:package_link, text: name)
          end

          def has_package?(name)
            has_element?(:package_link, text: name)
          end

          def has_no_package?(name)
            has_no_element?(:package_link, text: name)
          end
        end
      end
    end
  end
end

QA::Page::Project::Packages::Index.prepend_mod_with('Page::Project::Packages::Index', namespace: QA)
