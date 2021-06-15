# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :github, :requires_admin do
    describe 'Project import' do
      let!(:api_client) { Runtime::API::Client.as_admin }
      let!(:group) { Resource::Group.fabricate_via_api! { |resource| resource.api_client = api_client } }
      let!(:user) do
        Resource::User.fabricate_via_api! do |resource|
          resource.api_client = api_client
          resource.hard_delete_on_api_removal = true
        end
      end

      let(:imported_project) do
        Resource::ProjectImportedFromGithub.fabricate_via_browser_ui! do |project|
          project.name = 'imported-project'
          project.group = group
          project.github_personal_access_token = Runtime::Env.github_access_token
          project.github_repository_path = 'gitlab-qa-github/test-project'
          project.api_client = api_client
        end
      end

      before do
        group.add_member(user, Resource::Members::AccessLevel::MAINTAINER)
      end

      after do
        user.remove_via_api!
      end

      it 'imports a GitHub repo', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1762' do
        Flow::Login.sign_in(as: user)

        imported_project.reload! # import the project and reload all fields

        aggregate_failures do
          verify_repository_import
          verify_issues_import
          verify_merge_requests_import
        end
      end

      def verify_repository_import
        expect(imported_project.api_response).to include(
          description: 'A new repo for test',
          import_status: 'finished',
          import_error: nil
        )
      end

      def verify_issues_import
        issues = imported_project.issues

        expect(issues.length).to eq(1)
        expect(issues.first).to include(
          title: 'This is a sample issue',
          description: "*Created by: gitlab-qa-github*\n\nThis is a sample first comment",
          labels: ['custom new label', 'good first issue', 'help wanted'],
          user_notes_count: 1
        )
      end

      def verify_merge_requests_import
        merge_requests = imported_project.merge_requests

        expect(merge_requests.length).to eq(1)
        expect(merge_requests.first).to include(
          title: 'Improve readme',
          state: 'opened',
          target_branch: 'main',
          source_branch: 'improve-readme',
          labels: %w[bug documentation],
          description: <<~DSC.strip
            *Created by: gitlab-qa-github*\n\nThis improves the README file a bit.\r\n\r\nTODO:\r\n\r\n \r\n\r\n- [ ] Do foo\r\n- [ ]  Make bar\r\n  - [ ]  Think about baz
          DSC
        )
      end
    end
  end
end
