# frozen_string_literal: true

module QA
  module Resource
    module Settings
      class HashedStorage < Base
        def fabricate!(*traits)
          raise ArgumentError unless traits.include?(:enabled)

          Page::Main::Login.perform(&:sign_in_using_credentials)
          Page::Main::Menu.perform(&:go_to_admin_area)
          Page::Admin::Menu.perform(&:go_to_repository_settings)

          Page::Admin::Settings::Repository.perform do |setting|
            setting.expand_repository_storage do |page|
              page.enable_hashed_storage
              page.save_settings
            end
          end

          QA::Page::Main::Menu.perform(&:sign_out)
        end
      end
    end
  end
end
