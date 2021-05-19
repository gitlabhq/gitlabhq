# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :requires_admin do
    describe 'Group bulk import' do
      let!(:api_client) { Runtime::API::Client.as_admin }
      let!(:user) do
        Resource::User.fabricate_via_api! do |usr|
          usr.api_client = api_client
          usr.hard_delete_on_api_removal = true
        end
      end

      let!(:personal_access_token) { Runtime::API::Client.new(user: user).personal_access_token }

      let!(:sandbox) do
        Resource::Sandbox.fabricate_via_api! do |group|
          group.api_client = api_client
        end
      end

      let!(:source_group) do
        Resource::Sandbox.fabricate_via_api! do |group|
          group.api_client = api_client
          group.path = "source-group-for-import-#{SecureRandom.hex(4)}"
        end
      end

      let!(:subgroup) do
        Resource::Group.fabricate_via_api! do |group|
          group.api_client = api_client
          group.sandbox = source_group
          group.path = "subgroup-for-import-#{SecureRandom.hex(4)}"
        end
      end

      let(:imported_group) do
        Resource::Group.new.tap do |group|
          group.api_client = api_client
          group.path = source_group.path
        end
      end

      let(:imported_subgroup) do
        Resource::Group.new.tap do |group|
          group.api_client = api_client
          group.sandbox = imported_group
          group.path = subgroup.path
        end
      end

      def staging?
        Runtime::Scenario.gitlab_address.include?('staging.gitlab.com')
      end

      before(:all) do
        Runtime::Feature.enable(:bulk_import)
        Runtime::Feature.enable(:top_level_group_creation_enabled) if staging?
      end

      before do
        sandbox.add_member(user, Resource::Members::AccessLevel::MAINTAINER)
        source_group.add_member(user, Resource::Members::AccessLevel::MAINTAINER)

        Flow::Login.sign_in(as: user)
        Page::Main::Menu.new.go_to_import_group
        Page::Group::New.new.connect_gitlab_instance(Runtime::Scenario.gitlab_address, personal_access_token)
      end

      it(
        'performs bulk group import from another gitlab instance',
        testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1785',
        exclude: { job: ['ce:relative_url', 'ee:relative_url'] } # https://gitlab.com/gitlab-org/gitlab/-/issues/330344
      ) do
        Page::Group::BulkImport.perform do |import_page|
          import_page.import_group(source_group.path, sandbox.path)

          aggregate_failures do
            expect(import_page).to have_imported_group(source_group.path, wait: 120)
            expect(imported_group).to eq(source_group)
            expect(imported_subgroup).to eq(subgroup)
          end
        end
      end

      after do
        user.remove_via_api!
        source_group.remove_via_api!
      end

      after(:all) do
        Runtime::Feature.disable(:bulk_import)
        Runtime::Feature.disable(:top_level_group_creation_enabled) if staging?
      end
    end
  end
end
