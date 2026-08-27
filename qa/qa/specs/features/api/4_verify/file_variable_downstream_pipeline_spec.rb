# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', feature_category: :pipeline_composition do
    describe 'Pipeline with file variables and downstream pipelines' do
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

      let(:upstream_pipeline) do
        create(:pipeline, project: upstream_project, id: upstream_project.latest_pipeline[:id])
      end

      let(:child_pipeline) do
        create(:pipeline, project: upstream_project, id: downstream_pipeline_id('trigger_child'))
      end

      let(:downstream_project_pipeline) do
        create(:pipeline, project: downstream_project, id: downstream_pipeline_id('trigger_downstream_project'))
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
        downstream_project.change_pipeline_variables_minimum_override_role('developer')

        add_file_variables_to_upstream_project
        add_ci_file(downstream_project, downstream_project_file)
        add_ci_file(upstream_project, upstream_project_files)
        Support::Waiter.wait_until(message: 'Wait for first pipeline creation') { upstream_project.pipelines.present? }

        wait_for_pipelines_to_succeed
      end

      after do
        [upstream_project_runner, downstream_project_runner].each(&:remove_via_api!)
      end

      it(
        'creates variable with file path in downstream pipelines and can read file variable content'
      ) do
        child_echo_job = job_from(child_pipeline, 'child_job_echo')
        child_cat_job = job_from(child_pipeline, 'child_job_cat')
        downstream_project_echo_job = job_from(downstream_project_pipeline, 'downstream_job_echo')
        downstream_project_cat_job = job_from(downstream_project_pipeline, 'downstream_job_cat')

        aggregate_failures do
          trace = child_echo_job.trace
          expect(trace).to match(expanded_path('run something -f', upstream_project, 'TEST_PROJECT_FILE'))
          expect(trace).to match(expanded_path('docker run --tlscacert=', upstream_project, 'DOCKER_CA_CERT'))
          expect(trace).to match(expanded_path('run --output=', upstream_project, 'DOCKER_CA_CERT.crt'))
          expect(trace).to match(expanded_path('Will read private key from', upstream_project, 'TEST_PROJECT_FILE'))

          trace = child_cat_job.trace
          expect(trace).to include('hello, this is test')
          expect(trace).to include('This is secret')

          trace = downstream_project_echo_job.trace
          expect(trace).to match(expanded_path('run something -f', downstream_project, 'TEST_PROJECT_FILE'))
          expect(trace).to match(expanded_path('docker run --tlscacert=', downstream_project, 'DOCKER_CA_CERT'))
          expect(trace).to match(expanded_path('run --output=', downstream_project, 'DOCKER_CA_CERT.crt'))
          expect(trace).to match(expanded_path('Will read private key from', downstream_project, 'TEST_PROJECT_FILE'))

          trace = downstream_project_cat_job.trace
          expect(trace).to include('hello, this is test')
          expect(trace).to include('This is secret')
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

      def wait_for_pipelines_to_succeed
        {
          'child' => child_pipeline,
          'downstream project' => downstream_project_pipeline,
          'upstream' => upstream_pipeline
        }.each do |name, pipeline|
          Support::Waiter.wait_until(
            max_duration: 300,
            sleep_interval: 5,
            message: "Wait for #{name} pipeline to finish: #{pipeline.web_url}"
          ) { pipeline.finished? }

          next if pipeline.status == 'success'

          raise "Expected #{name} pipeline to succeed, got '#{pipeline.status}': #{pipeline.web_url}"
        end
      end

      def downstream_pipeline_id(bridge_name)
        bridge = nil

        Support::Waiter.wait_until(
          max_duration: 120,
          sleep_interval: 5,
          raise_on_failure: false,
          retry_on_exception: true,
          message: "Wait for bridge '#{bridge_name}' to create a downstream pipeline"
        ) do
          bridge = upstream_pipeline.pipeline_bridges.find { |candidate| candidate[:name] == bridge_name }
          bridge&.dig(:downstream_pipeline, :id)
        end

        raise "Bridge '#{bridge_name}' not found on pipeline #{upstream_pipeline.web_url}" unless bridge

        downstream_id = bridge.dig(:downstream_pipeline, :id)
        return downstream_id if downstream_id

        raise "Bridge '#{bridge_name}' (job #{bridge[:id]}) created no downstream pipeline. " \
          "Bridge status: '#{bridge[:status]}', failure reason: #{bridge[:failure_reason].inspect}. " \
          "The bridge job page on #{upstream_pipeline.web_url} shows why the downstream pipeline was rejected."
      end

      # Scoped to the pipeline, so the extra pipeline from the `.gitlab-ci.yml` commit is not picked up.
      def job_from(pipeline, job_name)
        job = pipeline.jobs.find { |candidate| candidate[:name] == job_name }
        raise "Job '#{job_name}' not found in pipeline #{pipeline.web_url}" unless job

        create(:job, project: pipeline.project, id: job[:id])
      end

      # Matches the expanded file variable path next to the text it was expanded into
      def expanded_path(prefix, project, file_name)
        %r{#{Regexp.escape(prefix)}[ \t]*\S*#{Regexp.escape(project.name)}\.tmp/#{Regexp.escape(file_name)}}
      end
    end
  end
end
