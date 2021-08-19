# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :requires_admin do
    describe 'Bulk group import' do
      let!(:staging?) { Runtime::Scenario.gitlab_address.include?('staging.gitlab.com') }

      let(:admin_api_client) { Runtime::API::Client.as_admin }
      let(:user) do
        Resource::User.fabricate_via_api! do |usr|
          usr.api_client = admin_api_client
          usr.hard_delete_on_api_removal = true
        end
      end

      let(:api_client) { Runtime::API::Client.new(user: user) }
      let(:personal_access_token) { api_client.personal_access_token }

      let(:sandbox) do
        Resource::Sandbox.fabricate_via_api! do |group|
          group.api_client = admin_api_client
        end
      end

      let(:source_group) do
        Resource::Sandbox.fabricate_via_api! do |group|
          group.api_client = api_client
          group.path = "source-group-for-import-#{SecureRandom.hex(4)}"
        end
      end

      let(:imported_group) do
        Resource::BulkImportGroup.init do |group|
          group.api_client = api_client
          group.sandbox = sandbox
          group.source_group_path = source_group.path
        end
      end

      before do
        Runtime::Feature.enable(:bulk_import) unless staging?
        Runtime::Feature.enable(:top_level_group_creation_enabled) if staging?

        sandbox.add_member(user, Resource::Members::AccessLevel::MAINTAINER)

        # create groups explicitly before connecting gitlab instance
        source_group

        Flow::Login.sign_in(as: user)
        Page::Main::Menu.perform(&:go_to_create_group)
        Page::Group::New.perform do |group|
          group.switch_to_import_tab
          group.connect_gitlab_instance(Runtime::Scenario.gitlab_address, personal_access_token)
        end
      end

      # Non blocking issues:
      # https://gitlab.com/gitlab-org/gitlab/-/issues/331252
      # https://gitlab.com/gitlab-org/gitlab/-/issues/333678 <- can cause 500 when creating user and group back to back
      it 'imports group from UI', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1785' do
        Page::Group::BulkImport.perform do |import_page|
          import_page.import_group(imported_group.path, imported_group.sandbox.path)

          expect(import_page).to have_imported_group(imported_group.path, wait: 300)

          imported_group.reload!.visit!
          Page::Group::Show.perform do |group|
            expect(group).to have_content(imported_group.path)
          end
        end
      end

      after do
        user.remove_via_api!
      ensure
        Runtime::Feature.disable(:bulk_import) unless staging?
        Runtime::Feature.disable(:top_level_group_creation_enabled) if staging?
      end
    end
  end
end
