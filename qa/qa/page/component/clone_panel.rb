# frozen_string_literal: true

module QA
  module Page
    module Component
      module ClonePanel
        extend QA::Page::PageConcern

        def repository_clone_http_location
          repository_clone_location('copy-http-url-input')
        end

        def repository_clone_ssh_location
          repository_clone_location('copy-ssh-url-input')
        end

        private

        def repository_clone_location(kind)
          wait_until(reload: false) do
            click_element 'code-dropdown'

            within_element 'code-dropdown' do
              Git::Location.new(find_element(kind).value)
            end
          end
        end
      end
    end
  end
end
