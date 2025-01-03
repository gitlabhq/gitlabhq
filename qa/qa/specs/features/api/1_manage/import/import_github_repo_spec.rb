# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', product_group: :import_and_integrate do
    describe 'GitHub import' do
      include_context 'with github import'

      before do
        QA::Support::Helpers::ImportSource.enable('github')
      end

      context 'when imported via api' do
        it 'imports project', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347670' do
          expect_project_import_finished_successfully

          aggregate_failures do
            verify_status_data
            verify_repository_import
            verify_protected_branches_import
            verify_commits_import
            verify_labels_import
            verify_issues_import
            verify_milestones_import
            verify_wikis_import
            verify_merge_requests_import
            verify_release_import
          end
        end

        def verify_status_data
          stats = imported_project.project_import_status.dig(:stats, :imported)
          expect(stats).to eq(
            issue: 1,
            issue_event: 10,
            pull_request: 1,
            pull_request_review: 2,
            diff_note: 1,
            label: 9,
            milestone: 1,
            note: 3,
            release: 1,
            protected_branch: 2
          )
        end

        def verify_repository_import
          expect(imported_project.reload!.description).to eq('Project for github import test')
          expect(imported_project.api_response[:import_error]).to be_nil
        end

        def verify_protected_branches_import
          imported_branches = imported_project.protected_branches.map do |branch|
            branch.slice(:name, :allow_force_push)
          end
          actual_branches = [
            {
              name: 'main',
              allow_force_push: false
            },
            {
              name: 'release',
              allow_force_push: true
            }
          ]

          expect(imported_branches).to match_array(actual_branches)
        end

        def verify_commits_import
          expect(imported_project.commits.length).to eq(2)
        end

        def verify_labels_import
          labels = imported_project.labels.map { |label| label.slice(:name, :color) }

          expect(labels).to include(
            { name: 'bug', color: '#d73a4a' },
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

        def verify_milestones_import
          milestones = imported_project.milestones

          expect(milestones.length).to eq(1)
          expect(milestones.first).to include(title: '0.0.1', description: nil, state: 'active')
        end

        def verify_wikis_import
          wikis = imported_project.wikis

          expect(wikis.length).to eq(1)
          expect(wikis.first).to include(title: 'Home', format: 'markdown')
        end

        def verify_issues_import
          issues = imported_project.issues
          issue = build(:issue,
            project: imported_project,
            iid: issues.first[:iid],
            api_client: user_api_client).reload!

          comments, events = fetch_events_and_comments(issue)

          expect(issues.length).to eq(1)
          expect(issue.api_resource).to include(
            title: 'Test issue',
            description: "Test issue description",
            labels: ['good first issue', 'help wanted', 'question']
          )
          expect(comments).to match_array(
            [
              "Some test comment",
              "Another test comment"
            ]
          )
          expect(events).to match_array(
            [
              { name: "add_label", label: "question" },
              { name: "add_label", label: "good first issue" },
              { name: "add_label", label: "help wanted" },
              { name: "add_milestone", label: "0.0.1" },
              { name: "closed" },
              { name: "reopened" }
            ]
          )
        end

        def verify_merge_requests_import
          merge_requests = imported_project.merge_requests
          merge_request = build(:merge_request,
            project: imported_project,
            iid: merge_requests.first[:iid],
            api_client: user_api_client).reload!

          comments, events = fetch_events_and_comments(merge_request)

          expect(merge_requests.length).to eq(1)
          expect(merge_request.api_resource).to include(
            title: 'Test pull request',
            state: 'opened',
            target_branch: 'main',
            source_branch: 'gitlab-qa-github-patch-1',
            labels: %w[documentation],
            description: "Test pull request body"
          )
          expect(comments).to match_array(
            [
              "**Review:** Commented\n\nGood but needs some improvement",
              "```suggestion:-0+0\nProject for GitHub import test to GitLab\r\n```",
              "Some test PR comment",
              "approved this merge request",
              "assigned to `@gitlab-qa-github`",
              "requested review from `@gitlab-qa`"
            ]
          )
          expect(events).to match_array(
            [
              { name: "add_label", label: "documentation" },
              { name: "add_milestone", label: "0.0.1" }
            ]
          )
        end

        def verify_release_import
          releases = imported_project.releases

          expect(releases.length).to eq(1)
          expect(releases.first).to include(
            tag_name: "0.0.1",
            name: "0.0.1",
            description: "Initial release",
            created_at: "2022-03-07T07:59:22.000Z",
            released_at: "2022-03-07T08:02:09.000Z"
          )
        end

        # Fetch events and comments from issue or mr
        #
        # @param [QA::Resource::Issuable] issuable
        # @return [Array]
        def fetch_events_and_comments(issuable)
          comments = issuable.comments.pluck(:body)
          events = [
            *issuable.label_events.map { |e| { name: "#{e[:action]}_label", label: e.dig(:label, :name) } },
            *issuable.state_events.map { |e| { name: e[:state] } },
            *issuable.milestone_events.map { |e| { name: "#{e[:action]}_milestone", label: e.dig(:milestone, :title) } }
          ]

          [comments, events]
        end
      end
    end
  end
end
