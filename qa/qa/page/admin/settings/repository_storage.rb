module QA
  module Page
    module Admin
      module Settings
        class RepositoryStorage < Page::Base
          view 'app/views/admin/application_settings/_repository_storage.html.haml' do
            element :submit, "submit 'Save changes'"
            element :hashed_storage,
              'Create new projects using hashed storage paths'
          end

          def enable_hashed_storage
            within_repository_storage do
              check 'Create new projects using hashed storage paths'
            end
          end

          def save_settings
            within_repository_storage do
              click_button 'Save changes'
            end
          end

          def within_repository_storage
            page.within('.as-repository-storage') do
              yield
            end
          end
        end
      end
    end
  end
end
