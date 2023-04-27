# frozen_string_literal: true

module QA
  RSpec.describe "Manage", :reliable, product_group: :import_and_integrate do
    include_context "with gitlab group migration"

    describe "Gitlab migration" do
      context 'with subgroups and labels' do
        let(:subgroup) do
          Resource::Group.fabricate_via_api! do |group|
            group.api_client = source_admin_api_client
            group.sandbox = source_group
            group.path = "subgroup-for-import-#{SecureRandom.hex(4)}"
          end
        end

        let(:imported_subgroup) do
          Resource::Group.init do |group|
            group.api_client = api_client
            group.sandbox = imported_group
            group.path = subgroup.path
          end
        end

        before do
          Resource::GroupLabel.fabricate_via_api! do |label|
            label.api_client = source_admin_api_client
            label.group = source_group
            label.title = "source-group-#{SecureRandom.hex(4)}"
          end
          Resource::GroupLabel.fabricate_via_api! do |label|
            label.api_client = source_admin_api_client
            label.group = subgroup
            label.title = "subgroup-#{SecureRandom.hex(4)}"
          end

          imported_group # trigger import
        end

        it(
          'successfully imports groups and labels',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347674'
        ) do
          expect_group_import_finished_successfully

          aggregate_failures do
            expect(imported_group.reload!).to eq(source_group)
            expect(imported_group.labels).to include(*source_group.labels)

            expect(imported_subgroup.reload!).to eq(subgroup)
            expect(imported_subgroup.labels).to include(*subgroup.labels)
          end
        end
      end

      context 'with milestones and badges' do
        let(:source_milestone) do
          Resource::GroupMilestone.fabricate_via_api! do |milestone|
            milestone.api_client = source_admin_api_client
            milestone.group = source_group
          end
        end

        before do
          source_milestone

          Resource::GroupBadge.fabricate_via_api! do |badge|
            badge.api_client = source_admin_api_client
            badge.group = source_group
            badge.link_url = "http://example.com/badge"
            badge.image_url = "http://shields.io/badge"
          end

          imported_group # trigger import
        end

        it(
          'successfully imports group milestones and badges',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347628'
        ) do
          expect_group_import_finished_successfully

          imported_milestone = imported_group.reload!.milestones.find { |ml| ml.title == source_milestone.title }
          aggregate_failures do
            expect(imported_milestone).to eq(source_milestone)
            expect(imported_milestone.iid).to eq(source_milestone.iid)
            expect(imported_milestone.created_at).to eq(source_milestone.created_at)
            expect(imported_milestone.updated_at).to eq(source_milestone.updated_at)

            expect(imported_group.badges).to eq(source_group.badges)
          end
        end
      end
    end
  end
end
