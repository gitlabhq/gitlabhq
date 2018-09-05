module QA
  module Page
    module Admin
      module Settings
        class Main < Page::Base
          include QA::Page::Settings::Common

          view 'app/views/admin/application_settings/show.html.haml' do
            element :terms_settings
          end

          def expand_repository_storage(&block)
            expand_section(:terms_settings) do
              RepositoryStorage.perform(&block)
            end
          end
        end
      end
    end
  end
end
