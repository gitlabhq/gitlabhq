# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', product_group: :import_and_integrate do
    describe 'Gitlab migration', :import, :orchestrated, requires_admin: 'creates a user via API' do
      include_context 'with gitlab project migration'

      let!(:source_issue) do
        create(:issue, project: source_project, labels: %w[label_one label_two], api_client: source_admin_api_client)
      end

      let(:source_issue_comments) do
        source_issue.comments.map do |note|
          { **note.except(:id, :noteable_id, :project_id), author: note[:author].except(:web_url) }
        end
      end

      let(:imported_issues) { imported_projects.first.issues }

      let(:imported_issue) do
        issue = imported_issues.first
        build(:issue, api_client: api_client, project: imported_projects.first, iid: issue[:iid])
      end

      let(:imported_issue_comments) do
        imported_issue.comments.map do |note|
          { **note.except(:id, :noteable_id, :project_id), author: note[:author].except(:web_url) }
        end
      end

      context 'with project issues' do
        let!(:source_comment) { source_issue.add_comment(body: 'This is a test comment!') }

        let(:imported_comments) { imported_issue.comments }

        it(
          'successfully imports issue',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347608',
          quarantine: {
            type: :stale,
            issue: "https://gitlab.com/gitlab-org/gitlab/-/issues/461222"
          }
        ) do
          expect_project_import_finished_successfully
          expect(imported_issues.count).to eq(1)
          expect(imported_issue).to eq(source_issue.reload!)
          expect(imported_issue_comments).to match_array(source_issue_comments)
        end
      end

      context 'with associated merge request' do
        let!(:source_mr) do
          create(:merge_request,
            project: source_project,
            api_client: source_admin_api_client,
            description: "Closes #{source_issue.web_url}")
        end

        let(:imported_related_mrs) do
          imported_issue.related_merge_requests.pluck(:iid)
        end

        it(
          'preserves related merge request',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/386305'
        ) do
          expect_project_import_finished_successfully
          expect(imported_related_mrs).to eq([source_mr.iid])
        end
      end

      context "with designs" do
        let!(:source_design) do
          Resource::Design.fabricate! do |design|
            design.api_client = source_admin_api_client
            design.issue = source_issue
          end
        end

        let(:imported_design) do
          build(:design, api_client: api_client, issue: imported_issue.reload!).reload!
        end

        it(
          'successfully imports design',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/366449'
        ) do
          expect_project_import_finished_successfully
          expect(imported_issues.count).to eq(1)

          expect(imported_design.full_path).to eq(source_design.full_path)
        end
      end
    end
  end
end
