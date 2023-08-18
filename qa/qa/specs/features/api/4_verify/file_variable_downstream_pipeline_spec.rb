# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_security, feature_flag: {
    name: 'ci_prevent_file_var_expansion_downstream_pipeline',
    scope: :project
  } do
    describe 'Pipeline with file variables and downstream pipelines' do
      let(:random_string) { Faker::Alphanumeric.alphanumeric(number: 8) }
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
      let!(:project) { create(:project, name: 'upstream-project-with-file-variables') }
      let!(:downstream_project) { create(:project, name: 'downstream-project') }

      let!(:project_runner) do
        Resource::ProjectRunner.fabricate! do |runner|
          runner.project = project
          runner.name = executor
          runner.tags = [executor]
        end
      end

      let!(:downstream_project_runner) do
        Resource::ProjectRunner.fabricate! do |runner|
          runner.project = downstream_project
          runner.name = "#{executor}-downstream"
          runner.tags = [executor]
        end
      end

      let(:add_ci_file) do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml and child.yml'
          commit.add_files(
            [
              {
                file_path: '.gitlab-ci.yml',
                content: <<~YAML
                  default:
                    tags: [#{executor}]

                  variables:
                    EXTRA_ARGS: "-f $TEST_PROJECT_FILE"
                    DOCKER_REMOTE_ARGS: --tlscacert="$DOCKER_CA_CERT"
                    EXTRACTED_CRT_FILE: ${DOCKER_CA_CERT}.crt
                    MY_FILE_VAR: $TEST_PROJECT_FILE

                  trigger_child:
                    trigger:
                      strategy: depend
                      include:
                        - local: child.yml

                  trigger_downstream_project:
                    trigger:
                      strategy: depend
                      project: #{downstream_project.path_with_namespace}

                YAML
              },
              {
                file_path: 'child.yml',
                content: <<~YAML
                  default:
                    tags: [#{executor}]

                  child_job_echo:
                    script:
                      - echo "run something $EXTRA_ARGS"
                      - echo "docker run $DOCKER_REMOTE_ARGS"
                      - echo "run --output=$EXTRACTED_CRT_FILE"
                      - echo "Will read private key from $MY_FILE_VAR"

                  child_job_cat:
                    script:
                      - cat "$MY_FILE_VAR"
                      - cat "$DOCKER_CA_CERT"
                YAML
              }
            ]
          )
        end
      end

      let(:add_downstream_project_ci_file) do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = downstream_project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files(
            [
              {
                file_path: '.gitlab-ci.yml',
                content: <<~YAML
                  default:
                    tags: [#{executor}]

                  downstream_job_echo:
                    script:
                      - echo "run something $EXTRA_ARGS"
                      - echo "docker run $DOCKER_REMOTE_ARGS"
                      - echo "run --output=$EXTRACTED_CRT_FILE"
                      - echo "Will read private key from $MY_FILE_VAR"

                  downstream_job_cat:
                    script:
                      - cat "$MY_FILE_VAR"
                      - cat "$DOCKER_CA_CERT"
                YAML
              }
            ]
          )
        end
      end

      let(:add_project_file_variables) do
        {
          'TEST_PROJECT_FILE' => "hello, this is test\n",
          'DOCKER_CA_CERT' => "This is secret\n"
        }.each do |file_name, content|
          add_file_variable_to_project(project, file_name, content)
        end
      end

      let(:upstream_pipeline) do
        Resource::Pipeline.fabricate_via_api! do |pipeline|
          pipeline.project = project
        end
      end

      def child_pipeline
        Resource::Pipeline.fabricate_via_api! do |pipeline|
          pipeline.project = project
          pipeline.id = upstream_pipeline.downstream_pipeline_id(bridge_name: 'trigger_child')
        end
      end

      def downstream_project_pipeline
        Resource::Pipeline.fabricate_via_api! do |pipeline|
          pipeline.project = downstream_project
          pipeline.id = upstream_pipeline.downstream_pipeline_id(bridge_name: 'trigger_downstream_project')
        end
      end

      around do |example|
        Runtime::Feature.enable(:ci_prevent_file_var_expansion_downstream_pipeline, project: project)
        example.run
        Runtime::Feature.disable(:ci_prevent_file_var_expansion_downstream_pipeline, project: project)
      end

      before do
        add_project_file_variables
        add_downstream_project_ci_file
        add_ci_file
        upstream_pipeline
        wait_for_pipelines
      end

      after do
        project_runner.remove_via_api!
        downstream_project_runner.remove_via_api!
      end

      it(
        'creates variable with file path in downstream pipelines and can read file variable content',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/416337'
      ) do
        child_echo_job = Resource::Job.fabricate_via_api! do |job|
          job.project = project
          job.id = project.job_by_name('child_job_echo')[:id]
        end

        child_cat_job = Resource::Job.fabricate_via_api! do |job|
          job.project = project
          job.id = project.job_by_name('child_job_cat')[:id]
        end

        downstream_project_echo_job = Resource::Job.fabricate_via_api! do |job|
          job.project = downstream_project
          job.id = downstream_project.job_by_name('downstream_job_echo')[:id]
        end

        downstream_project_cat_job = Resource::Job.fabricate_via_api! do |job|
          job.project = downstream_project
          job.id = downstream_project.job_by_name('downstream_job_cat')[:id]
        end

        aggregate_failures do
          trace = child_echo_job.trace
          expect(trace).to include('run something -f', "#{project.name}.tmp/TEST_PROJECT_FILE")
          expect(trace).to include('docker run --tlscacert=', "#{project.name}.tmp/DOCKER_CA_CERT")
          expect(trace).to include('run --output=', "#{project.name}.tmp/DOCKER_CA_CERT.crt")
          expect(trace).to include('Will read private key from', "#{project.name}.tmp/TEST_PROJECT_FILE")

          trace = child_cat_job.trace
          expect(trace).to have_content('hello, this is test')
          expect(trace).to have_content('This is secret')

          trace = downstream_project_echo_job.trace
          expect(trace).to include('run something -f', "#{downstream_project.name}.tmp/TEST_PROJECT_FILE")
          expect(trace).to include('docker run --tlscacert=', "#{downstream_project.name}.tmp/DOCKER_CA_CERT")
          expect(trace).to include('run --output=', "#{downstream_project.name}.tmp/DOCKER_CA_CERT.crt")
          expect(trace).to include('Will read private key from', "#{downstream_project.name}.tmp/TEST_PROJECT_FILE")

          trace = downstream_project_cat_job.trace
          expect(trace).to have_content('hello, this is test')
          expect(trace).to have_content('This is secret')
        end
      end

      private

      def add_file_variable_to_project(project, key, value)
        Resource::CiVariable.fabricate_via_api! do |ci_variable|
          ci_variable.project = project
          ci_variable.key = key
          ci_variable.value = value
          ci_variable.variable_type = 'file'
        end
      end

      def wait_for_pipelines
        Support::Waiter.wait_until(max_duration: 300, sleep_interval: 10) do
          upstream_pipeline.reload!
          upstream_pipeline.status == 'success' &&
            child_pipeline.status == 'success' &&
            downstream_project_pipeline.status == 'success'
        end
      end
    end
  end
end
