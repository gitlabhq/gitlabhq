# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'Gitlab migration', product_group: :import do
      include_context 'with gitlab project migration'

      let!(:source_project_with_readme) { true }

      # We create additional user so that object being migrated is not owned by the user doing migration
      let!(:other_user) do
        Resource::User
          .fabricate_via_api! { |usr| usr.api_client = admin_api_client }
          .tap do |usr|
            usr.set_public_email
            source_project.add_member(usr, Resource::Members::AccessLevel::MAINTAINER)
          end
      end

      let!(:source_mr) do
        Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.project = source_project
          mr.api_client = Runtime::API::Client.new(user: other_user)
          mr.reviewer_ids = [other_user.id]
        end
      end

      let!(:source_comment) { source_mr.add_comment(body: 'This is a test comment!') }

      let(:imported_mrs) { imported_project.merge_requests }
      let(:imported_mr_comments) { imported_mr.comments.map { |note| note.except(:id, :noteable_id) } }
      let(:source_mr_comments) { source_mr.comments.map { |note| note.except(:id, :noteable_id) } }

      let(:imported_mr) do
        Resource::MergeRequest.init do |mr|
          mr.project = imported_project
          mr.iid = imported_mrs.first[:iid]
          mr.api_client = api_client
        end
      end

      let(:imported_mr_reviewers) { imported_mr.reviewers.map { |r| r.slice(:name, :username) } }
      let(:source_mr_reviewers) { [{ name: other_user.name, username: other_user.username }] }

      let(:imported_mr_approvers) do
        imported_mr.approval_configuration[:approved_by].map do |usr|
          { username: usr.dig(:user, :username), name: usr.dig(:user, :name) }
        end
      end

      before do
        source_project.update_approval_configuration(
          merge_requests_author_approval: true,
          approvals_before_merge: 1
        )
        source_mr.approve
      end

      after do
        other_user.remove_via_api!
      end

      context 'with merge request' do
        it(
          'successfully imports merge request',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348478'
        ) do
          expect_import_finished
          expect(imported_mrs.count).to eq(1)

          aggregate_failures do
            expect(imported_mr).to eq(source_mr.reload!)

            expect(imported_mr_comments).to match_array(source_mr_comments)
            expect(imported_mr_reviewers).to eq(source_mr_reviewers)
            expect(imported_mr_approvers).to eq([{ username: other_user.username, name: other_user.name }])
          end
        end
      end
    end
  end
end
