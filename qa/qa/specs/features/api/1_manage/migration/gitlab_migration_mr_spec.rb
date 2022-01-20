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

      context 'with merge request' do
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
          end
        end

        let!(:source_comment) { source_mr.add_comment('This is a test comment!') }

        let(:imported_mrs) { imported_project.merge_requests }
        let(:imported_mr_comments) { imported_mr.comments }

        let(:imported_mr) do
          Resource::MergeRequest.init do |mr|
            mr.project = imported_project
            mr.iid = imported_mrs.first[:iid]
            mr.api_client = api_client
          end
        end

        after do
          other_user.remove_via_api!
        end

        it(
          'successfully imports merge request',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348478'
        ) do
          expect_import_finished

          aggregate_failures do
            expect(imported_mrs.count).to eq(1)
            # TODO: remove custom comparison after member migration is implemented
            # https://gitlab.com/gitlab-org/gitlab/-/issues/341886
            expect(imported_mr.comparable.except(:author)).to eq(source_mr.reload!.comparable.except(:author))

            expect(imported_mr_comments.count).to eq(1)
            expect(imported_mr_comments.first[:body]).to include(source_comment[:body])
            # Comment will have mention of original user since members are not migrated yet
            expect(imported_mr_comments.first[:body]).to include(other_user.name)
          end
        end
      end
    end
  end
end
