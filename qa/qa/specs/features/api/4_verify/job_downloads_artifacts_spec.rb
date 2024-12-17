# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', product_group: :pipeline_execution do
    describe 'Job artifacts' do
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
      let(:project) { create(:project, name: 'project-for-job-artifacts-fetching') }
      let(:random_test_string) { Faker::Alphanumeric.alphanumeric(number: 8) }
      let!(:runner) { create(:project_runner, project: project, name: executor, tags: [executor]) }

      let!(:add_ci_file) do
        create(:commit, project: project, commit_message: 'Add CI file for job artifacts test', actions: [
          {
            action: 'create',
            file_path: '.gitlab-ci.yml',
            content: <<~YAML
              default:
                tags: ["#{executor}"]

              stages:
                - build
                - test

              job_creates_artifacts:
                stage: build
                script: mkdir tmp; echo #{random_test_string} > tmp/output.xml
                artifacts:
                  paths:
                    - tmp

              job_with_default_settings:
                stage: test
                script: cat $CI_PROJECT_DIR/tmp/output.xml

              job_with_empty_dependencies:
                stage: test
                dependencies: []
                script: cat $CI_PROJECT_DIR/tmp/output.xml
            YAML
          }
        ])
      end

      let(:job_with_default_settings) do
        create(:job, project: project, id: project.job_by_name('job_with_default_settings')[:id])
      end

      let(:job_with_empty_dependencies) do
        create(:job, project: project, id: project.job_by_name('job_with_empty_dependencies')[:id])
      end

      let(:job_creates_artifacts) do
        create(:job, project: project, id: project.job_by_name('job_creates_artifacts')[:id])
      end

      before do
        # Pipeline is expected to fail here when it finishes because
        # job_with_empty_dependencies shouldn't be able to read $CI_PROJECT_DIR/tmp/output.xml
        Support::Waiter.wait_until(message: 'Wait for pipeline to finish') do
          project.pipelines.present? && project.latest_pipeline[:status] == 'failed'
        end
      end

      after do
        runner.remove_via_api!
      end

      it 'are not downloaded when dependencies array is set to empty',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/424958' do
        # If this job fails, the 'failed' status of pipeline is no longer helpful
        # We should exit the test case here
        # And might want to see why this job fails for investing purposes
        expect(job_creates_artifacts.status).to eq('success'),
          "Expected job to succeed but #{job_creates_artifacts.status} - Trace : \n#{job_creates_artifacts.trace}"

        aggregate_failures 'each job trace' do
          trace = job_with_default_settings.trace
          expect(trace).to include('Downloading artifacts from coordinator', random_test_string),
            'Job fails to download and open artifact from previous stage as expected.'

          trace = job_with_empty_dependencies.trace
          expect(trace).to include('cat $CI_PROJECT_DIR/tmp/output.xml', 'No such file or directory'),
            'Job downloads and opens artifact from previous stage even though not expected to.'
        end
      end
    end
  end
end
