module QA
  module Page
    module Admin
      module Settings
        class Main < Page::Base
          include QA::Page::Settings::Common

          view 'app/views/admin/application_settings/show.html.haml' do
            element :repository_storage_settings
          end

          def expand_repository_storage(&block)
            expand_section(:repository_storage_settings) do
              RepositoryStorage.perform(&block)
            end
          end
        end
      end
    end
  end
end
