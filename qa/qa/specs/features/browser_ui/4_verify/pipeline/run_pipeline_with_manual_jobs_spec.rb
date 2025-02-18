# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_execution do
    describe 'Run pipeline with manual jobs' do
      let(:executor) { "qa-runner-#{SecureRandom.hex(4)}" }

      let(:project) do
        create(:project, name: 'pipeline-with-manual-job', description: 'Project for pipeline with manual job')
      end

      let!(:runner) do
        create(:project_runner,
          project: project,
          tags: [executor],
          name: executor)
      end

      let!(:ci_file) do
        create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
          {
            action: 'create',
            file_path: '.gitlab-ci.yml',
            content: <<~YAML
              default:
                tags: ["#{executor}"]

              stages:
                - Stage1
                - Stage2
                - Stage3

              Prep:
                stage: Stage1
                script: exit 0
                when: manual

              Build:
                stage: Stage2
                needs: ['Prep']
                script: exit 0
                parallel: 6

              Test:
                stage: Stage3
                needs: ['Build']
                script: exit 0

              Deploy:
                stage: Stage3
                needs: ['Test']
                script: exit 0
                parallel: 6
            YAML
          }
        ])
      end

      before do
        Flow::Login.sign_in
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
        Flow::Pipeline.wait_for_latest_pipeline_to_have_status(project: project, status: 'skipped')
        project.visit_latest_pipeline
      end

      after do
        runner.remove_via_api!
      end

      it(
        'does not leave any job in skipped state',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/349158'
      ) do
        Page::Project::Pipeline::Show.perform do |show|
          show.click_job_action('Prep') # Trigger pipeline manually
          Flow::Pipeline.wait_for_latest_pipeline_to_have_status(project: project, status: 'success', wait: 300)

          aggregate_failures do
            expect(show).to have_build('Test', status: :success)

            show.click_job_dropdown('Build')
            expect(show).not_to have_skipped_job_in_group

            show.click_job_dropdown('Build') # Close Build dropdown
            show.click_job_dropdown('Deploy')
            expect(show).not_to have_skipped_job_in_group
          end
        end
      end
    end
  end
end
