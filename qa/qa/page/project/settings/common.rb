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

          # Click the Expand button present in the specified section
          #
          # @param [String] name present in the container in the DOM
          def expand_section(name)
            page.within('#content-body') do
              page.within('section', text: name) do
                click_button('Expand')

                yield if block_given?
              end
            end
          end
        end
      end
    end
  end
end
