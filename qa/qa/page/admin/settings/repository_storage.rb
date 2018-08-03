module QA
  module Page
    module Admin
      module Settings
        class RepositoryStorage < Page::Base
          view 'app/views/admin/application_settings/_repository_storage.html.haml' do
            element :submit, "submit 'Save changes'"
            element :hashed_storage,
              'Use hashed storage paths for newly created and renamed projects'
          end

          def enable_hashed_storage
            check 'Use hashed storage paths for newly created and renamed projects'
          end

          def save_settings
            click_button 'Save changes'
          end
        end
      end
    end
  end
end
