# frozen_string_literal: true

require_relative 'gitlab_project_migration_common'

module QA
  RSpec.describe 'Manage' do
    describe 'Gitlab migration' do
      include_context 'with gitlab project migration'

      let!(:source_issue) do
        Resource::Issue.fabricate_via_api! do |issue|
          issue.api_client = api_client
          issue.project = source_project
          issue.labels = %w[label_one label_two]
        end
      end

      let(:imported_issues) { imported_projects.first.issues }

      let(:imported_issue) do
        issue = imported_issues.first
        Resource::Issue.init do |resource|
          resource.api_client = api_client
          resource.project = imported_projects.first
          resource.iid = issue[:iid]
        end
      end

      context 'with project issues' do
        let!(:source_comment) { source_issue.add_comment(body: 'This is a test comment!') }

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

      context "with designs" do
        let!(:source_design) do
          Flow::Login.sign_in(as: user)

          Resource::Design.fabricate_via_browser_ui! do |design|
            design.api_client = api_client
            design.issue = source_issue
          end.reload!
        end

        let(:imported_design) do
          Resource::Design.init do |design|
            design.api_client = api_client
            design.issue = imported_issue.reload!
          end.reload!
        end

        it(
          'successfully imports design',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/366449'
        ) do
          expect_import_finished
          expect(imported_issues.count).to eq(1)

          expect(imported_design.full_path).to eq(source_design.full_path)
        end
      end
    end
  end
end
