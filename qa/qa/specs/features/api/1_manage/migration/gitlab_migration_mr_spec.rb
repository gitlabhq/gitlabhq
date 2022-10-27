# frozen_string_literal: true

require_relative 'gitlab_project_migration_common'

module QA
  RSpec.describe 'Manage' do
    describe 'Gitlab migration', product_group: :import do
      include_context 'with gitlab project migration'

      let!(:source_project_with_readme) { true }

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

      let(:imported_reviewers) { imported_mr.reviewers.map { |r| r.slice(:id, :username) } }
      let(:source_mr_reviewers) { [{ id: other_user.id, username: other_user.username }] }

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
            expect(imported_reviewers).to eq(source_mr_reviewers)
          end
        end
      end
    end
  end
end
