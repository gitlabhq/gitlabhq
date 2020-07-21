# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        class Repository < Page::Base
          include QA::Page::Settings::Common

          view 'app/views/admin/application_settings/repository.html.haml' do
            element :repository_storage_settings_content
          end

          def expand_repository_storage(&block)
            expand_content(:repository_storage_settings_content) do
              Component::RepositoryStorage.perform(&block)
            end
          end
        end
      end
    end
  end
end
