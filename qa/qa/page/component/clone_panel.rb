# frozen_string_literal: true

module QA
  module Page
    module Component
      module ClonePanel
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/views/projects/buttons/_code.html.haml' do
            element 'clone-dropdown'
            element 'clone-dropdown-content'
            element 'ssh-clone-url-content'
            element 'http-clone-url-content'
          end
        end

        def repository_clone_http_location
          repository_clone_location('http-clone-url-content')
        end

        def repository_clone_ssh_location
          repository_clone_location('ssh-clone-url-content')
        end

        private

        def repository_clone_location(kind)
          wait_until(reload: false) do
            click_element 'clone-dropdown'

            within_element 'clone-dropdown-content' do
              Git::Location.new(find_element(kind).value)
            end
          end
        end
      end
    end
  end
end
