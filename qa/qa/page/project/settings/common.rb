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
            within_section(name) do
              # Don't expand if it's already expanded
              click_button 'Expand' unless first('button', text: 'Collapse')

              yield
            end
          end

          def within_section(name)
            page.within('#content-body') do
              page.within('section', text: name) do
                yield
              end
            end
          end
        end
      end
    end
  end
end
