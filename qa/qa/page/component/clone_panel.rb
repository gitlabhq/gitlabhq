# frozen_string_literal: true

module QA
  module Page
    module Component
      module ClonePanel
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/views/projects/buttons/_code.html.haml' do
            element :clone_dropdown
            element :clone_dropdown_content
            element :ssh_clone_url_content
            element :http_clone_url_content
          end
        end

        def repository_clone_http_location
          repository_clone_location(:http_clone_url_content)
        end

        def repository_clone_ssh_location
          repository_clone_location(:ssh_clone_url_content)
        end

        private

        def repository_clone_location(kind)
          wait_until(reload: false) do
            click_element :clone_dropdown

            within_element :clone_dropdown_content do
              Git::Location.new(find_element(kind).value)
            end
          end
        end
      end
    end
  end
end
