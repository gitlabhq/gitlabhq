# frozen_string_literal: true

module QA
  RSpec.describe 'Manage' do
    describe 'Gitlab migration', product_group: :import do
      include_context 'with gitlab project migration'

      let(:member) do
        Resource::User.fabricate_via_api! do |usr|
          usr.api_client = admin_api_client
          usr.hard_delete_on_api_removal = true
        end
      end

      let(:imported_group_member) do
        imported_group.reload!.list_members.find { |usr| usr['username'] == member.username }
      end

      let(:imported_project_member) do
        imported_project.reload!.list_members.find { |usr| usr['username'] == member.username }
      end

      before do
        member.set_public_email
      end

      after do
        member.remove_via_api!
      end

      context 'with group member' do
        before do
          source_group.add_member(member, Resource::Members::AccessLevel::DEVELOPER)
        end

        it(
          'member retains indirect membership in imported project',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/354416'
        ) do
          expect_import_finished

          aggregate_failures do
            expect(imported_project_member).to be_nil
            expect(imported_group_member&.fetch('access_level')).to eq(
              Resource::Members::AccessLevel::DEVELOPER
            )
          end
        end
      end

      context 'with project member' do
        before do
          source_project.add_member(member, Resource::Members::AccessLevel::DEVELOPER)
        end

        it(
          'member retains direct membership in imported project',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/354417'
        ) do
          expect_import_finished

          aggregate_failures do
            expect(imported_group_member).to be_nil
            expect(imported_project_member&.fetch('access_level')).to eq(
              Resource::Members::AccessLevel::DEVELOPER
            )
          end
        end
      end
    end
  end
end
