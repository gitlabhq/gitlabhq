# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :runner do
    describe 'Runner registration' do
      let(:executor) { "qa-runner-#{SecureRandom.hex(6)}" }
      let!(:runner) { create(:project_runner, name: executor, tags: ['e2e-test']) }

      after do
        runner.remove_via_api!
      end

      it 'user registers a new project runner', :blocking, testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348025' do
        Flow::Login.sign_in

        runner.project.visit!

        Page::Project::Menu.perform(&:go_to_ci_cd_settings)
        Page::Project::Settings::CiCd.perform do |settings|
          settings.expand_runners_settings do |page|
            expect(page).to have_content(executor)
            expect(page).to have_online_runner
          end
        end
      end
    end
  end
end
