module QA
  module Page
    module Project
      class Show < Page::Base
        def choose_repository_clone_http
          find('#clone-dropdown').click

          page.within('#clone-dropdown') do
            find('span', text: 'HTTP').click
          end
        end

        def repository_location
          find('#project_clone').value
        end

        def wait_for_push
          sleep 5
        end
      end
    end
  end
end
