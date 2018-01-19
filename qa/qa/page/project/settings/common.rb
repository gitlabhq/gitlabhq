module QA
  module Page
    module Project
      module Settings
        module Common
          def self.included(base)
            base.class_eval do
              view 'app/views/projects/edit.html.haml' do
                element :advanced_settings_expand, "= expanded ? 'Collapse' : 'Expand'"
              end
            end
          end

          def expand_section(selector)
            page.within(selector) do
              find_button('Expand').click

              yield if block_given?
            end
          end
        end
      end
    end
  end
end
