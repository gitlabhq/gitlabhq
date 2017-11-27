module QA
  module Page
    module Admin
      class Settings < Page::Base
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
