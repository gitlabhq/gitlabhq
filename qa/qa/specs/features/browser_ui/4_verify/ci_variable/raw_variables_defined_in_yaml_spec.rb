# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner do
    describe 'Pipeline with raw variables in YAML', product_group: :pipeline_authoring, feature_flag: {
      name: 'ci_raw_variables_in_yaml_config',
      scope: :project
    } do
      let(:executor) { "qa-runner-#{Time.now.to_i}" }
      let(:pipeline_job_name) { 'rspec' }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-raw-variable-pipeline'
        end
      end

      let!(:runner) do
        Resource::Runner.fabricate! do |runner|
          runner.project = project
          runner.name = executor
          runner.tags = [executor]
        end
      end

      let(:commit_ci_file) do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files(
            [
              {
                file_path: '.gitlab-ci.yml',
                content: <<~YAML
                  variables:
                    VAR7:
                      value: "value 7 $CI_PIPELINE_ID"
                      expand: false
                    VAR8:
                      value: "value 8 $CI_PIPELINE_ID"
                      expand: false

                  #{pipeline_job_name}:
                    tags:
                      - #{executor}
                    script:
                      - echo "VAR1 is $VAR1"
                      - echo "VAR2 is $VAR2"
                      - echo "VAR3 is $VAR3"
                      - echo "VAR4 is $VAR4"
                      - echo "VAR5 is $VAR5"
                      - echo "VAR6 is $VAR6"
                      - echo "VAR7 is $VAR7"
                      - echo "VAR8 is $VAR8"
                    variables:
                      VAR1: "JOBID-$CI_JOB_ID"
                      VAR2: "PIPELINEID-$CI_PIPELINE_ID and $VAR1"
                      VAR3:
                        value: "PIPELINEID-$CI_PIPELINE_ID and $VAR1"
                        expand: false
                      VAR4:
                        value: "JOBID-$CI_JOB_ID"
                        expand: false
                      VAR5: "PIPELINEID-$CI_PIPELINE_ID and $VAR4"
                      VAR6:
                        value: "PIPELINEID-$CI_PIPELINE_ID and $VAR4"
                        expand: false
                      VAR7: "overridden value 7 $CI_PIPELINE_ID"
                YAML
              }
            ]
          )
        end
      end

      let(:pipeline_id) { project.pipelines.first[:id] }
      let(:job_id) { project.job_by_name(pipeline_job_name)[:id] }

      def before_do
        # TODO: Switch to use `let!` and remove this line when removing FF
        commit_ci_file

        Flow::Login.sign_in
        project.visit!
        Flow::Pipeline.visit_latest_pipeline(status: 'passed')
        Page::Project::Pipeline::Show.perform do |show|
          show.click_job(pipeline_job_name)
        end
      end

      after do
        runner&.remove_via_api!
      end

      context 'when FF is on', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/381487' do
        before do
          Runtime::Feature.enable(:ci_raw_variables_in_yaml_config, project: project)
          sleep 60

          before_do
        end

        it 'expands variables according to expand: true/false', :aggregate_failures do
          Page::Project::Job::Show.perform do |show|
            expect(show.output).to have_content("VAR1 is JOBID-#{job_id}")
            expect(show.output).to have_content("VAR2 is PIPELINEID-#{pipeline_id} and JOBID-#{job_id}")
            expect(show.output).to have_content("VAR3 is PIPELINEID-$CI_PIPELINE_ID and $VAR1")
            expect(show.output).to have_content("VAR4 is JOBID-$CI_JOB_ID")
            expect(show.output).to have_content("VAR5 is PIPELINEID-#{pipeline_id} and JOBID-$CI_JOB_ID")
            expect(show.output).to have_content("VAR6 is PIPELINEID-$CI_PIPELINE_ID and $VAR4")
            expect(show.output).to have_content("VAR7 is overridden value 7 #{pipeline_id}")
            expect(show.output).to have_content("VAR8 is value 8 $CI_PIPELINE_ID")
          end
        end
      end

      # TODO: Remove this context when FF :ci_raw_variables_in_yaml_config is removed
      # Also archive testcase and close related issue
      context 'when FF is off',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/381486',
        quarantine: {
          issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/381806',
          only: { pipeline: %w[staging staging-canary staging-ref] },
          type: :waiting_on
        } do
        before do
          Runtime::Feature.disable(:ci_raw_variables_in_yaml_config, project: project)
          sleep 60

          before_do
        end

        it 'expands all variables', :aggregate_failures do
          Page::Project::Job::Show.perform do |show|
            expect(show.output).to have_content("VAR1 is JOBID-#{job_id}")
            expect(show.output).to have_content("VAR2 is PIPELINEID-#{pipeline_id} and JOBID-#{job_id}")
            expect(show.output).to have_content("VAR3 is PIPELINEID-#{pipeline_id} and JOBID-#{job_id}")
            expect(show.output).to have_content("VAR4 is JOBID-#{job_id}")
            expect(show.output).to have_content("VAR5 is PIPELINEID-#{pipeline_id} and JOBID-#{job_id}")
            expect(show.output).to have_content("VAR6 is PIPELINEID-#{pipeline_id} and JOBID-#{job_id}")
            expect(show.output).to have_content("VAR7 is overridden value 7 #{pipeline_id}")
            expect(show.output).to have_content("VAR8 is value 8 #{pipeline_id}")
          end
        end
      end
    end
  end
end
