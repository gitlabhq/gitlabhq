module QA
  module Page
    module Settings
      module Common
        # Click the Expand button present in the specified section
        #
        # @param [String] name present in the container in the DOM
        def expand_section(name)
          page.within('#content-body') do
            page.within('section', text: name) do
              # Because it is possible to click the button before the JS toggle code is bound
              wait(reload: false) do
                click_button 'Expand' unless first('button', text: 'Collapse')

                page.has_content?('Collapse')
              end

              yield if block_given?
            end
          end
        end
      end
    end
  end
end
