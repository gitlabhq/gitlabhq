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
        'user registers a new group runner', :blocking,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/388740'
      ) do
        Flow::Login.sign_in

        runner.group.visit!

        Page::Group::Menu.perform(&:go_to_runners)

        Support::Retrier.retry_on_exception(sleep_interval: 2, message: "Retry failed when looking for runner name") do
          expect(page).to have_content(executor)
        end
      end
    end
  end
end
