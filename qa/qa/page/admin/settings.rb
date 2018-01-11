module QA
  module Page
    module Admin
      class Settings < Page::Base
        ##
        # TODO, define all selectors required by this page object
        #
        # See gitlab-org/gitlab-qa#154
        #
        view 'app/views/admin/application_settings/show.html.haml'

        def enable_hashed_storage
          scroll_to 'legend', text: 'Repository Storage'
          check 'Create new projects using hashed storage paths'
        end

        def save_settings
          scroll_to '.form-actions' do
            click_button 'Save'
          end
        end
      end
    end
  end
end
