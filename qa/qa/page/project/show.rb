module QA
  module Page
    module Project
      class Show < Page::Base
        ##
        # TODO, define all selectors required by this page object
        #
        # See gitlab-org/gitlab-qa#154
        #
        view 'app/views/projects/show.html.haml'

        def choose_repository_clone_http
          find('#clone-dropdown').click

          page.within('.clone-options-dropdown') do
            click_link('HTTP')
          end
        end

        def repository_location
          find('#project_clone').value
        end

        def project_name
          find('.project-title').text
        end

        def wait_for_push
          sleep 5
        end
      end
    end
  end
end
