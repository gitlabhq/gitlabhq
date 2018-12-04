module QA
  module Page
    module Project
      module Settings
        module Common
          include QA::Page::Settings::Common

          def self.included(base)
            base.class_eval do
              view 'app/views/projects/edit.html.haml' do
                element :advanced_settings_expand, "= expanded ? 'Collapse' : 'Expand'" # rubocop:disable QA/ElementWithPattern
              end
            end
          end
        end
      end
    end
  end
end
