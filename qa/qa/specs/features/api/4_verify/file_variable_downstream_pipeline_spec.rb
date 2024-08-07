# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_authoring,
    only: { subdomain: 'staging-canary' } do
    # Runs this test only in staging-canary to debug flakiness https://gitlab.com/gitlab-org/gitlab/-/issues/424903
    # We need to collect failure data, please don't quarantine for the time being
    describe 'Pipeline with file variables and downstream pipelines' do
      let(:random_string) { Faker::Alphanumeric.alphanumeric(number: 8) }
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
      let!(:upstream_project) { create(:project, name: 'upstream-project-with-file-variables') }
      let!(:downstream_project) { create(:project, name: 'downstream-project') }

      let!(:upstream_project_runner) do
        create(:project_runner,
          project: upstream_project,
          name: executor,
          tags: [executor])
      end

      let!(:downstream_project_runner) do
        create(:project_runner,
          project: downstream_project,
          name: "#{executor}-downstream",
          tags: [executor])
      end

      let(:upstream_project_files) do
        [
          {
            action: 'create',
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
            action: 'create',
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
      end

      let(:downstream_project_file) do
        [
          {
            action: 'create',
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
      end

      before do
        add_file_variables_to_upstream_project
        add_ci_file(downstream_project, downstream_project_file)
        add_ci_file(upstream_project, upstream_project_files)
        Support::Waiter.wait_until(message: 'Wait for first pipeline creation') { upstream_project.pipelines.present? }

        wait_for_pipelines_to_finish
      end

      after do
        [upstream_project_runner, downstream_project_runner].each(&:remove_via_api!)
      end

      it(
        'creates variable with file path in downstream pipelines and can read file variable content',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/416337'
      ) do
        child_echo_job = create(:job, project: upstream_project,
          id: upstream_project.job_by_name('child_job_echo')[:id])

        child_cat_job = create(:job, project: upstream_project, id: upstream_project.job_by_name('child_job_cat')[:id])

        downstream_project_echo_job = create(:job,
          project: downstream_project,
          id: downstream_project.job_by_name('downstream_job_echo')[:id])

        downstream_project_cat_job = create(:job,
          project: downstream_project,
          id: downstream_project.job_by_name('downstream_job_cat')[:id])

        aggregate_failures do
          trace = child_echo_job.trace
          expect(trace).to include('run something -f', "#{upstream_project.name}.tmp/TEST_PROJECT_FILE")
          expect(trace).to include('docker run --tlscacert=', "#{upstream_project.name}.tmp/DOCKER_CA_CERT")
          expect(trace).to include('run --output=', "#{upstream_project.name}.tmp/DOCKER_CA_CERT.crt")
          expect(trace).to include('Will read private key from', "#{upstream_project.name}.tmp/TEST_PROJECT_FILE")

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

      def add_file_variables_to_upstream_project
        {
          'TEST_PROJECT_FILE' => "hello, this is test\n",
          'DOCKER_CA_CERT' => "This is secret\n"
        }.each do |file_name, content|
          create(:ci_variable, project: upstream_project, key: file_name, value: content, variable_type: 'file')
        end
      end

      def add_ci_file(project, files)
        create(:commit, project: project, commit_message: 'Add CI files to project', actions: files)
      end

      def wait_for_pipelines_to_finish
        Support::Waiter.wait_until(max_duration: 300, sleep_interval: 10) do
          upstream_pipeline.status == 'success' &&
            child_pipeline.status == 'success' &&
            downstream_project_pipeline.status == 'success'
        end
      end

      # Fetch upstream project's parent pipeline
      def upstream_pipeline
        create(:pipeline, project: upstream_project, id: upstream_project.latest_pipeline[:id])
      end

      # Fetch upstream project's child pipeline
      def child_pipeline
        create(:pipeline,
          project: upstream_project,
          id: upstream_pipeline.downstream_pipeline_id(bridge_name: 'trigger_child'))
      end

      # Fetch downstream project's pipeline
      def downstream_project_pipeline
        create(:pipeline,
          project: downstream_project,
          id: upstream_pipeline.downstream_pipeline_id(bridge_name: 'trigger_downstream_project'))
      end
    end
  end
end
