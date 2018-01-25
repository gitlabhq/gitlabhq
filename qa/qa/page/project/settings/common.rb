module QA
  module Page
    module Project
      module Settings
        module Common
          def expand(element_name)
            page.within('#content-body') do
              click_element(element_name)

              yield
            end
          end

          def expand_section(name)
            page.within('#content-body') do
              page.within('section', text: name) do
                click_button 'Expand'

                yield.tap do
                  click_button 'Collapse' if first('button', text: 'Collapse')
                end
              end
            end
          end
        end
      end
    end
  end
end
