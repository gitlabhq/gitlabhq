# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :runner do
    describe 'Runner registration' do
      let(:executor) { "qa-runner-#{SecureRandom.hex(6)}" }
      let!(:runner) { create(:project_runner, name: executor, tags: [executor]) }
      let!(:runner_managers) { create_list(:runner_manager, 2, runner: runner) }
      let(:expected_job_log) { "Runner was registered successfully" }

      after do
        runner.remove_via_api!
      end

      it 'user registers a new project runner and executes a job',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348025' do
        Flow::Login.sign_in

        runner.project.visit!

        Page::Project::Menu.perform(&:go_to_ci_cd_settings)
        Page::Project::Settings::CiCd.perform do |settings|
          settings.expand_runners_settings do |page|
            expect(page).to have_content(executor)
            expect(page).to have_online_runner
          end
        end
        create_commit

        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: runner.project, wait: 40)
        Flow::Pipeline.wait_for_latest_pipeline_to_have_status(project: runner.project, status: 'success', wait: 60)

        runner.project.visit_job('job')
        Page::Project::Job::Show.perform do |show|
          expect(show.output).to have_content(expected_job_log),
            "Didn't find expected text within job's log:\n#{show.output}."
        end
      end

      def create_commit
        create(:commit, project: runner.project, commit_message: 'Add .gitlab-ci.yml', actions: [
          {
            action: 'create',
            file_path: '.gitlab-ci.yml',
            content: <<~YAML
              job:
                tags:
                  - #{executor}
                script: echo "#{expected_job_log}"
            YAML
          }
        ])
      end
    end
  end
end
