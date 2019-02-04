# frozen_string_literal: true

module QA
  module Page
    module Admin
      module Settings
        module Component
          class RepositoryStorage < Page::Base
            view 'app/views/admin/application_settings/_repository_storage.html.haml' do
              element :hashed_storage_checkbox
              element :save_changes_button
            end

            def enable_hashed_storage
              check_element :hashed_storage_checkbox
            end

            def save_settings
              click_element :save_changes_button
            end
          end
        end
      end
    end
  end
end
