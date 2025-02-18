# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :runner do
    describe 'Group runner registration' do
      let(:executor) { "qa-runner-#{SecureRandom.hex(6)}" }
      let!(:runner) { create(:group_runner, name: executor) }

      after do
        runner.remove_via_api!
      end

      it(
        'user registers a new group runner',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/388740'
      ) do
        Flow::Login.sign_in

        runner.group.visit!

        Page::Group::Menu.perform(&:go_to_runners)

        Page::Group::Runners::Index.perform do |group_runners|
          expect { group_runners.has_active_runner?(runner) }.to eventually_be(true).within(sleep_interval: 2)

          group_runners.go_to_runner_managers_page(runner)
        end

        Page::Runners::RunnerManagersDetail.perform do |runner_managers|
          runner_managers.expand_runners
          expect(runner_managers).to have_online_runner
        end
      end
    end
  end
end
