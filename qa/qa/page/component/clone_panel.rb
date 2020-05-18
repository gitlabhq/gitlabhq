# frozen_string_literal: true

module QA
  module Page
    module Component
      module ClonePanel
        extend QA::Page::PageConcern

        def self.included(base)
          super

          base.view 'app/views/projects/buttons/_clone.html.haml' do
            element :clone_dropdown
            element :clone_options
            element :ssh_clone_url
            element :http_clone_url
          end
        end

        def repository_clone_http_location
          repository_clone_location(:http_clone_url)
        end

        def repository_clone_ssh_location
          repository_clone_location(:ssh_clone_url)
        end

        private

        def repository_clone_location(kind)
          wait_until(reload: false) do
            click_element :clone_dropdown

            within_element :clone_options do
              Git::Location.new(find_element(kind).value)
            end
          end
        end
      end
    end
  end
end
