module QA
  module Page
    module Admin
      class Settings < Page::Base
        view 'app/views/admin/application_settings/_form.html.haml' do
          element :form_actions, '.form-actions'
          element :submit, "submit 'Save'"
          element :repository_storage, '%legend Repository Storage'
          element :hashed_storage,
            'Create new projects using hashed storage paths'
        end

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
