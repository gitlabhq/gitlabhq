# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner do
    describe 'Pipeline with raw variables in YAML', product_group: :pipeline_authoring do
      let(:executor) { "qa-runner-#{SecureRandom.hex(6)}" }
      let(:pipeline_job_name) { 'rspec' }
      let(:project) { create(:project, name: 'project-with-raw-variable-pipeline') }
      let!(:runner) { create(:project_runner, project: project, name: executor, tags: [executor]) }

      let!(:commit_ci_file) do
        create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
          {
            action: 'create',
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
        ])
      end

      let(:pipeline_id) { project.pipelines.first[:id] }
      let(:job_id) { project.job_by_name(pipeline_job_name)[:id] }

      before do
        Flow::Login.sign_in
        project.visit!
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
        Flow::Pipeline.wait_for_latest_pipeline_to_have_status(project: project, status: 'success')
        project.visit_job(pipeline_job_name)
      end

      after do
        runner.remove_via_api!
      end

      it(
        'expands variables according to expand: true/false', :smoke,
        :aggregate_failures,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/381487'
      ) do
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
  end
end
