module QA
  module Page
    module Project
      module Settings
        class DeployKeys < Page::Base
          ##
          # TODO, define all selectors required by this page object
          #
          # See gitlab-org/gitlab-qa#154
          #
          view 'app/views/projects/deploy_keys/edit.html.haml'

          def fill_key_title(title)
            fill_in 'deploy_key_title', with: title
          end

          def fill_key_value(key)
            fill_in 'deploy_key_key', with: key
          end

          def add_key
            click_on 'Add key'
          end

          def has_key_title?(title)
            page.within('.deploy-keys') do
              page.find('.title', text: title)
            end
          end
        end
      end
    end
  end
end
