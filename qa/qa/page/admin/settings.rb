module QA
  module Page
    module Admin
      class Settings < Page::Base
        def enable_hashed_storage
          # TODO need to scroll to "Repository storage" text
          scroll_to 'application_setting_clientside_sentry_dsn'
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
