# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :fleet_visibility, product_group: :runner do
    describe 'Runner fleet management' do
      let(:executor) { "qa-runner-#{SecureRandom.hex(6)}" }

      let!(:runner) { create(:group_runner, name: executor) }

      after do
        runner.remove_via_api!
      end

      it(
        'shows group runner online count',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/421255'
      ) do
        Flow::Login.sign_in

        runner.group.visit!

        Page::Group::Menu.perform(&:go_to_runners)
        online_runners = Page::Group::Runners::Index.perform(&:count_online_runners)

        expect(online_runners).to be >= 1
      end
    end
  end
end
