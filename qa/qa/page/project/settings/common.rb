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
                # Because it is possible to click the button before the JS toggle code is bound
                wait(reload: false) do
                  click_button('Expand')

                  page.has_content?('Collapse')
                end

                yield
              end
            end
          end
        end
      end
    end
  end
end
