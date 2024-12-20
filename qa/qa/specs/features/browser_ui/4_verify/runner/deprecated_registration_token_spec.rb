# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :runner do
    describe 'Group runner with deprecated registration token' do
      let(:executor) { "qa-runner-#{SecureRandom.hex(6)}" }
      let!(:runner) do
        create(:deprecated_group_runner,
          name: executor,
          tags: [SecureRandom.hex(6), SecureRandom.hex(6)])
      end

      after do
        runner.remove_via_api!
      end

      it(
        'user registers a new group runner',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/510298'
      ) do
        Flow::Login.sign_in

        runner.group.visit!

        Page::Group::Menu.perform(&:go_to_runners)

        Page::Group::Runners::Index.perform do |group_runners|
          Support::Retrier.retry_on_exception(sleep_interval: 2, message: "Retry failed to verify online runner") do
            expect(group_runners).to have_active_runner(runner)
            expect(group_runners).to have_runner_with_expected_tags(runner)
          end
        end
      end
    end
  end
end
