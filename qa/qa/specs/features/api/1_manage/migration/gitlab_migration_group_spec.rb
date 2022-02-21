# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :requires_admin do
    describe 'Gitlab migration' do
      let(:import_wait_duration) { { max_duration: 300, sleep_interval: 2 } }
      let(:admin_api_client) { Runtime::API::Client.as_admin }
      let(:user) do
        Resource::User.fabricate_via_api! do |usr|
          usr.api_client = admin_api_client
          usr.hard_delete_on_api_removal = true
        end
      end

      let(:api_client) { Runtime::API::Client.new(user: user) }

      let(:sandbox) do
        Resource::Sandbox.fabricate_via_api! do |group|
          group.api_client = admin_api_client
        end
      end

      let(:destination_group) do
        Resource::Group.fabricate_via_api! do |group|
          group.api_client = api_client
          group.sandbox = sandbox
          group.path = "destination-group-for-import-#{SecureRandom.hex(4)}"
        end
      end

      let(:source_group) do
        Resource::Group.fabricate_via_api! do |group|
          group.api_client = api_client
          group.sandbox = sandbox
          group.path = "source-group-for-import-#{SecureRandom.hex(4)}"
          group.avatar = File.new('qa/fixtures/designs/tanuki.jpg', 'r')
        end
      end

      let(:imported_group) do
        Resource::BulkImportGroup.fabricate_via_api! do |group|
          group.api_client = api_client
          group.sandbox = destination_group
          group.source_group = source_group
        end
      end

      let(:import_failures) do
        imported_group.import_details.sum([]) { |details| details[:failures] }
      end

      before do
        sandbox.add_member(user, Resource::Members::AccessLevel::MAINTAINER)
      end

      after do |example|
        # Checking for failures in the test currently makes test very flaky due to catching unrelated failures
        # Log failures for easier debugging
        Runtime::Logger.warn("Import failures: #{import_failures}") if example.exception && !import_failures.empty?
      ensure
        user.remove_via_api!
      end

      context 'with subgroups and labels' do
        let(:subgroup) do
          Resource::Group.fabricate_via_api! do |group|
            group.api_client = api_client
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
            label.api_client = api_client
            label.group = source_group
            label.title = "source-group-#{SecureRandom.hex(4)}"
          end
          Resource::GroupLabel.fabricate_via_api! do |label|
            label.api_client = api_client
            label.group = subgroup
            label.title = "subgroup-#{SecureRandom.hex(4)}"
          end

          imported_group # trigger import
        end

        it(
          'successfully imports groups and labels',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347674'
        ) do
          expect { imported_group.import_status }.to eventually_eq('finished').within(import_wait_duration)

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
            milestone.api_client = api_client
            milestone.group = source_group
          end
        end

        before do
          source_milestone

          Resource::GroupBadge.fabricate_via_api! do |badge|
            badge.api_client = api_client
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
          expect { imported_group.import_status }.to eventually_eq('finished').within(import_wait_duration)

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

      context 'with group members' do
        let(:member) do
          Resource::User.fabricate_via_api! do |usr|
            usr.api_client = admin_api_client
            usr.hard_delete_on_api_removal = true
          end
        end

        before do
          member.set_public_email
          source_group.add_member(member, Resource::Members::AccessLevel::DEVELOPER)

          imported_group # trigger import
        end

        after do
          member.remove_via_api!
        end

        it(
          'adds members for imported group',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347609'
        ) do
          expect { imported_group.import_status }.to eventually_eq('finished').within(import_wait_duration)

          imported_member = imported_group.reload!.members.find { |usr| usr.username == member.username }
          aggregate_failures do
            expect(imported_member).not_to be_nil
            expect(imported_member.access_level).to eq(Resource::Members::AccessLevel::DEVELOPER)
          end
        end
      end
    end
  end
end
