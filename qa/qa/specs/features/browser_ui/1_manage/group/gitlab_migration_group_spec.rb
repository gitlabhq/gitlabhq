# frozen_string_literal: true

module QA
  describe 'Manage', :requires_admin do
    describe 'Gitlab migration', quarantine: {
      only: { subdomain: :staging },
      issue: "https://gitlab.com/gitlab-org/gitlab/-/issues/349556",
      type: :bug
    } do
      let!(:staging?) { Runtime::Scenario.gitlab_address.include?('staging.gitlab.com') }
      let!(:admin_api_client) { Runtime::API::Client.as_admin }
      let!(:user) do
        Resource::User.fabricate_via_api! do |usr|
          usr.api_client = admin_api_client
          usr.hard_delete_on_api_removal = true
        end
      end

      let!(:api_client) { Runtime::API::Client.new(user: user) }
      let!(:personal_access_token) { api_client.personal_access_token }

      let(:sandbox) do
        Resource::Sandbox.fabricate_via_api! do |group|
          group.api_client = admin_api_client
        end
      end

      let(:source_group) do
        Resource::Sandbox.fabricate! do |group|
          group.api_client = api_client
          group.path = "source-group-for-import-#{SecureRandom.hex(4)}"
        end
      end

      let(:imported_group) do
        Resource::BulkImportGroup.init do |group|
          group.api_client = api_client
          group.sandbox = sandbox
          group.source_group = source_group
        end
      end

      before do
        sandbox.add_member(user, Resource::Members::AccessLevel::MAINTAINER)

        Flow::Login.sign_in(as: user)

        source_group

        Page::Main::Menu.perform(&:go_to_create_group)
        Page::Group::New.perform do |group|
          group.switch_to_import_tab
          group.connect_gitlab_instance(Runtime::Scenario.gitlab_address, personal_access_token)
        end
      end

      after do
        user.remove_via_api!
      end

      it(
        'imports group from UI',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347862',
        issue_1: 'https://gitlab.com/gitlab-org/gitlab/-/issues/331252',
        issue_2: 'https://gitlab.com/gitlab-org/gitlab/-/issues/333678',
        issue_3: 'https://gitlab.com/gitlab-org/gitlab/-/issues/332351',
        except: { job: 'instance-image-slow-network' }
      ) do
        Page::Group::BulkImport.perform do |import_page|
          import_page.import_group(imported_group.path, imported_group.sandbox.path)

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
