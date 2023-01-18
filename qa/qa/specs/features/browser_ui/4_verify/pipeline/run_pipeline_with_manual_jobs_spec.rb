# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_execution do
    describe 'Run pipeline with manual jobs' do
      let(:executor) { "qa-runner-#{SecureRandom.hex(4)}" }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'pipeline-with-manual-job'
          project.description = 'Project for pipeline with manual job'
        end
      end

      let!(:runner) do
        Resource::ProjectRunner.fabricate! do |runner|
          runner.project = project
          runner.name = executor
          runner.tags = [executor]
        end
      end

      let!(:ci_file) do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files(
            [
              {
                file_path: '.gitlab-ci.yml',
                content: <<~YAML
                  stages:
                    - Stage1
                    - Stage2
                    - Stage3

                  Prep:
                    stage: Stage1
                    tags: ["#{executor}"]
                    script: exit 0
                    when: manual

                  Build:
                    stage: Stage2
                    tags: ["#{executor}"]
                    needs: ['Prep']
                    script: exit 0
                    parallel: 6

                  Test:
                    stage: Stage3
                    tags: ["#{executor}"]
                    needs: ['Build']
                    script: exit 0

                  Deploy:
                    stage: Stage3
                    tags: ["#{executor}"]
                    needs: ['Test']
                    script: exit 0
                    parallel: 6
                YAML
              }
            ]
          )
        end
      end

      before do
        Flow::Login.sign_in
        project.visit!
        Flow::Pipeline.visit_latest_pipeline(status: 'skipped')
      end

      after do
        runner&.remove_via_api!
      end

      it(
        'does not leave any job in skipped state',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/349158'
      ) do
        Page::Project::Pipeline::Show.perform do |show|
          show.click_job_action('Prep') # Trigger pipeline manually

          show.wait_until(max_duration: 300, sleep_interval: 2, reload: false) do
            project.pipelines.last[:status] == 'success'
          end

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
