# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_security do
    describe 'Pipeline with project file variables' do
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-file-variables'
        end
      end

      let!(:runner) do
        Resource::ProjectRunner.fabricate! do |runner|
          runner.project = project
          runner.name = executor
          runner.tags = [executor]
        end
      end

      let(:add_ci_file) do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files(
            [
              {
                file_path: '.gitlab-ci.yml',
                content: <<~YAML
                  default:
                    tags: [#{executor}]

                  variables:
                    EXTRA_ARGS: "-f $TEST_FILE"
                    DOCKER_REMOTE_ARGS: --tlscacert="$DOCKER_CA_CERT"
                    EXTRACTED_CRT_FILE: ${DOCKER_CA_CERT}.crt
                    MY_FILE_VAR: $TEST_FILE

                  job_echo:
                    script:
                      - echo "run something $EXTRA_ARGS"
                      - echo "docker run $DOCKER_REMOTE_ARGS"
                      - echo "run --output=$EXTRACTED_CRT_FILE"
                      - echo "Will read private key from $MY_FILE_VAR"

                  job_cat:
                    script:
                      - cat "$MY_FILE_VAR"
                      - cat "$DOCKER_CA_CERT"
                YAML
              }
            ]
          )
        end
      end

      let(:add_file_variables) do
        {
          'TEST_FILE' => "hello, this is test\n",
          'DOCKER_CA_CERT' => "This is secret\n"
        }.each do |file_name, content|
          add_file_variable_to_project(file_name, content)
        end
      end

      before do
        add_file_variables
        add_ci_file
        trigger_pipeline
        wait_for_pipeline
      end

      after do
        runner.remove_via_api!
      end

      it(
        'does not expose file variable content with echo',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/370791'
      ) do
        job = Resource::Job.fabricate_via_api! do |job|
          job.project = project
          job.id = project.job_by_name('job_echo')[:id]
        end

        aggregate_failures do
          trace = job.trace
          expect(trace).to include('run something -f', "#{project.name}.tmp/TEST_FILE")
          expect(trace).to include('docker run --tlscacert=', "#{project.name}.tmp/DOCKER_CA_CERT")
          expect(trace).to include('run --output=', "#{project.name}.tmp/DOCKER_CA_CERT.crt")
          expect(trace).to include('Will read private key from', "#{project.name}.tmp/TEST_FILE")
        end
      end

      it(
        'can read file variable content with cat',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/386409'
      ) do
        job = Resource::Job.fabricate_via_api! do |job|
          job.project = project
          job.id = project.job_by_name('job_cat')[:id]
        end

        aggregate_failures do
          trace = job.trace
          expect(trace).to have_content('hello, this is test')
          expect(trace).to have_content('This is secret')
        end
      end

      private

      def add_file_variable_to_project(key, value)
        Resource::CiVariable.fabricate_via_api! do |ci_variable|
          ci_variable.project = project
          ci_variable.key = key
          ci_variable.value = value
          ci_variable.variable_type = 'file'
        end
      end

      def trigger_pipeline
        Resource::Pipeline.fabricate_via_api! do |pipeline|
          pipeline.project = project
        end
      end

      def wait_for_pipeline
        Support::Waiter.wait_until do
          project.pipelines.present? && project.pipelines.first[:status] == 'success'
        end
      end
    end
  end
end
