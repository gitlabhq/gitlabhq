# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', feature_category: :runner_core do
    describe 'Runner' do
      let(:executor) { "qa-runner-#{SecureRandom.hex(6)}" }
      let!(:runner) { create(:project_runner, name: executor, tags: ["e2e-test-#{SecureRandom.hex(6)}"]) }

      after do
        runner.remove_via_api!
      end

      it 'user unregisters a runner with authentication token',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/510652' do
        Flow::Login.sign_in

        runner.project.visit!

        Page::Project::Menu.perform(&:go_to_ci_cd_settings)
        Page::Project::Settings::CiCd.perform do |settings|
          settings.expand_runners_settings do |page|
            expect(page).to have_content(executor)
            expect(page).to have_online_runner
          end
        end

        # The output of the unregister command is verified inside the GitlabRunner class
        runner.unregister!
      end
    end
  end
end
