module QA
  module Page
    module Project
      module Settings
        module Common
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
