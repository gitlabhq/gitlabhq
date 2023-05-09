# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :runner,
    quarantine: {
      only: { job: 'airgapped' },
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/390184',
      type: :stale
    } do
    describe 'Group runner registration' do
      let(:executor) { "qa-runner-#{Time.now.to_i}" }

      let!(:runner) do
        Resource::GroupRunner.fabricate! do |runner|
          runner.name = executor
        end
      end

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

        expect(page).to have_content(executor)
      end
    end
  end
end
