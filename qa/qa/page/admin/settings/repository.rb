# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        class Repository < Page::Base
          include QA::Page::Settings::Common

          view 'app/views/admin/application_settings/repository.html.haml' do
            element :repository_storage
          end

          def expand_repository_storage(&block)
            expand_section(:repository_storage) do
              RepositoryStorage.perform(&block)
            end
          end
        end
      end
    end
  end
end
