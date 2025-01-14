# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', product_group: :runner do
    describe 'Runner' do
      let(:executor) { "qa-runner-#{SecureRandom.hex(6)}" }
      let!(:runner) { create(:deprecated_group_runner, name: executor, tags: ["e2e-test-#{SecureRandom.hex(6)}"]) }

      after do
        runner.remove_via_api!
        # Skip 404 since the test deletes the runner by unregistering in this case
      rescue StandardError => e
        raise e unless e.message.include?('404')
      end

      it 'user unregisters a runner with deprecated registration token',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/510655' do
        Flow::Login.sign_in

        runner.group.visit!

        Page::Group::Menu.perform(&:go_to_runners)

        Page::Group::Runners::Index.perform do |group_runners|
          expect { group_runners.has_active_runner?(runner) }.to eventually_be(true).within(sleep_interval: 2)
        end

        runner.unregister!

        Page::Group::Runners::Index.perform do |group_runners|
          group_runners.refresh
          expect { group_runners.has_no_runner?(runner) }.to eventually_be(true).within(sleep_interval: 2)
        end
      end
    end
  end
end
