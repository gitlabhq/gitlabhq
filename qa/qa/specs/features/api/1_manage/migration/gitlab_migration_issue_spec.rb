# frozen_string_literal: true

require_relative 'gitlab_project_migration_common'

module QA
  RSpec.describe 'Manage', :requires_admin do
    describe 'Gitlab migration', quarantine: {
      only: { job: 'praefect' },
      type: :investigating,
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/348999'
    } do
      include_context 'with gitlab project migration'

      context 'with project issues' do
        let!(:source_issue) do
          Resource::Issue.fabricate_via_api! do |issue|
            issue.api_client = api_client
            issue.project = source_project
            issue.labels = %w[label_one label_two]
          end
        end

        let!(:source_comment) { source_issue.add_comment(body: 'This is a test comment!') }

        let(:imported_issues) { imported_projects.first.issues }

        let(:imported_issue) do
          issue = imported_issues.first
          Resource::Issue.init do |resource|
            resource.api_client = api_client
            resource.project = imported_projects.first
            resource.iid = issue[:iid]
          end
        end

        let(:imported_comments) { imported_issue.comments }

        it(
          'successfully imports issue',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347608'
        ) do
          expect_import_finished
          expect(imported_issues.count).to eq(1)

          aggregate_failures do
            expect(imported_issue).to eq(source_issue.reload!)

            expect(imported_comments.count).to eq(1)
            expect(imported_comments.first&.fetch(:body)).to include(source_comment[:body])
          end
        end
      end
    end
  end
end
