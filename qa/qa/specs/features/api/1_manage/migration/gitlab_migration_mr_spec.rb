# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'Gitlab migration', product_group: :import_and_integrate do
      include_context 'with gitlab project migration'

      let!(:source_project_with_readme) { true }

      let!(:source_mr_reviewer) do
        reviewer = Resource::User.fabricate_via_api! do |usr|
          usr.api_client = source_admin_api_client
          usr.username = "source-reviewer-#{SecureRandom.hex(6)}"
        end
        reviewer.tap do |usr|
          usr.set_public_email
          source_project.add_member(usr, Resource::Members::AccessLevel::MAINTAINER)
        end
      end

      let!(:source_mr) do
        Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.project = source_project
          mr.api_client = source_admin_api_client
          mr.reviewer_ids = [source_mr_reviewer.id]
        end
      end

      let!(:mr_reviewer) do
        Resource::User.fabricate_via_api! do |usr|
          usr.api_client = admin_api_client
          usr.email = source_mr_reviewer.email
        end.tap(&:set_public_email)
      end

      let!(:source_mr_reviewers) { [source_mr_reviewer.email] }
      let!(:source_mr_approvers) { [source_admin_user.email] }
      let(:source_mr_comments) do
        source_mr.comments.map do |note|
          { **note.except(:id, :noteable_id, :project_id), author: note[:author].except(:web_url) }
        end
      end

      let(:imported_mrs) { imported_project.merge_requests }
      let(:imported_mr) do
        Resource::MergeRequest.init do |mr|
          mr.project = imported_project
          mr.iid = imported_project.merge_requests.first[:iid]
          mr.api_client = api_client
        end
      end

      let(:imported_mr_comments) do
        imported_mr.comments.map do |note|
          { **note.except(:id, :noteable_id, :project_id), author: note[:author].except(:web_url) }
        end
      end

      let(:imported_mr_reviewers) { imported_mr.reviewers.pluck(:username) }
      let(:imported_mr_approvers) do
        imported_mr.approval_configuration[:approved_by].map { |usr| usr.dig(:user, :username) }
      end

      before do
        source_project.update_approval_configuration(merge_requests_author_approval: true, approvals_before_merge: 1)
        source_mr.approve
        source_mr.add_comment(body: 'This is a test comment!')
      end

      context 'with merge request' do
        it(
          'successfully imports merge request',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348478'
        ) do
          expect_project_import_finished_successfully
          expect(imported_mrs.count).to eq(1)

          aggregate_failures do
            expect(imported_mr).to eq(source_mr.reload!)

            expect(imported_mr_comments).to match_array(source_mr_comments)
            expect(imported_mr_reviewers).to eq([mr_reviewer.username])
            expect(imported_mr_approvers).to eq([source_admin_user.username])
          end
        end
      end
    end
  end
end
