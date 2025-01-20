# frozen_string_literal: true

module QA
  describe 'Manage', product_group: :import_and_integrate do
    describe 'Gitlab migration', :import, :orchestrated, requires_admin: 'creates a user via API' do
      include_context "with gitlab group migration"

      let!(:imported_group) do
        Resource::BulkImportGroup.init do |group|
          group.api_client = api_client
          group.sandbox = target_sandbox
          group.source_group = source_group
        end
      end

      before do
        Flow::Login.sign_in(as: user)

        Page::Main::Menu.perform(&:go_to_create_group)
        Page::Group::New.perform do |group|
          group.switch_to_import_tab
          group.connect_gitlab_instance(source_gitlab_address, source_admin_api_client.personal_access_token)
        end
      end

      it 'imports group from UI', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347862' do
        Page::Group::BulkImport.perform do |import_page|
          import_page.import_group(source_group.path, target_sandbox.path)

          expect(import_page).to have_imported_group(imported_group.path, wait: 300)

          imported_group.reload!.visit!
          Page::Group::Show.perform do |group|
            expect(group).to have_content(imported_group.path)
          end
        end
      end
    end
  end
end
