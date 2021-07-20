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
        Resource::ProjectImportedFromGithub.fabricate_via_api! do |project|
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

      it 'imports Github repo via api', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1858' do
        imported_project # import the project

        expect { imported_project.reload!.import_status }.to eventually_eq('finished').within(duration: 90)

        aggregate_failures do
          verify_repository_import
          verify_commits_import
          verify_labels_import
          verify_issues_import
          verify_milestones_import
          verify_wikis_import
          verify_merge_requests_import
        end
      end

      def verify_repository_import
        expect(imported_project.api_response).to include(
          description: 'A new repo for test',
          import_error: nil
        )
      end

      def verify_commits_import
        expect(imported_project.commits.length).to eq(20)
      end

      def verify_labels_import
        labels = imported_project.labels.map { |label| label.slice(:name, :color) }

        expect(labels).to include(
          { name: 'bug', color: '#d73a4a' },
          { name: 'custom new label', color: '#fc8f91' },
          { name: 'documentation', color: '#0075ca' },
          { name: 'duplicate', color: '#cfd3d7' },
          { name: 'enhancement', color: '#a2eeef' },
          { name: 'good first issue', color: '#7057ff' },
          { name: 'help wanted', color: '#008672' },
          { name: 'invalid', color: '#e4e669' },
          { name: 'question', color: '#d876e3' },
          { name: 'wontfix', color: '#ffffff' }
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

      def verify_milestones_import
        milestones = imported_project.milestones

        expect(milestones.length).to eq(1)
        expect(milestones.first).to include(title: 'v1.0', description: nil, state: 'active')
      end

      def verify_wikis_import
        wikis = imported_project.wikis

        expect(wikis.length).to eq(1)
        expect(wikis.first).to include(title: 'Home', format: 'markdown')
      end

      def verify_merge_requests_import
        merge_requests = imported_project.merge_requests
        merge_request = Resource::MergeRequest.init do |mr|
          mr.project = imported_project
          mr.iid = merge_requests.first[:iid]
          mr.api_client = api_client
        end.reload!
        mr_comments = merge_request.comments.map { |comment| comment[:body] } # rubocop:disable Rails/Pluck

        expect(merge_requests.length).to eq(1)
        expect(merge_request.api_resource).to include(
          title: 'Improve readme',
          state: 'opened',
          target_branch: 'main',
          source_branch: 'improve-readme',
          labels: %w[bug documentation],
          description: <<~DSC.strip
            *Created by: gitlab-qa-github*\n\nThis improves the README file a bit.\r\n\r\nTODO:\r\n\r\n \r\n\r\n- [ ] Do foo\r\n- [ ]  Make bar\r\n  - [ ]  Think about baz
          DSC
        )
        expect(mr_comments).to eq(
          [
            "*Created by: gitlab-qa-github*\n\n[PR comment by @sliaquat] Nice work! ",
            "*Created by: gitlab-qa-github*\n\n[Single diff comment] Nice addition",
            "*Created by: gitlab-qa-github*\n\n[Single diff comment] Good riddance"
          ]
        )
      end
    end
  end
end
