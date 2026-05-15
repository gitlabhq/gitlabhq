# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', feature_category: :pipeline_composition do
    describe 'Pipeline with project file variables' do
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
      let(:project) { create(:project, name: 'project-with-file-variables') }
      let!(:runner) { create(:project_runner, project: project, name: executor, tags: [executor]) }

      let(:add_ci_file) do
        create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
          {
            action: 'create',
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
        ])
      end

      let(:add_file_variables) do
        {
          'TEST_FILE' => "hello, this is test\n",
          'DOCKER_CA_CERT' => "This is secret\n"
        }.each do |file_name, content|
          add_file_variable_to_project(file_name, content)
        end
      end

      let(:pipeline) { create(:pipeline, project: project) }

      before do
        add_file_variables
        add_ci_file
        pipeline
        wait_for_pipeline
      end

      after do
        unless pipeline.finished?
          pipeline.cancel!
          pipeline.wait_until_finished
        end
      rescue StandardError => e
        Runtime::Logger.warn("Could not cancel pipeline: #{e.message}")
      ensure
        runner.remove_via_api!
      end

      it(
        'does not expose file variable content with echo',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/370791'
      ) do
        job = create(:job, project: project, id: project.job_by_name('job_echo')[:id])

        trace = Support::Waiter.wait_until(max_duration: 60, sleep_interval: 5,
          message: 'Wait for job trace to be available') do
          t = job.trace
          t.presence || false
        end

        aggregate_failures do
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
        job = create(:job, project: project, id: project.job_by_name('job_cat')[:id])

        trace = Support::Waiter.wait_until(max_duration: 60, sleep_interval: 5,
          message: 'Wait for job trace to be available') do
          t = job.trace
          t.presence || false
        end

        aggregate_failures do
          expect(trace).to have_content('hello, this is test')
          expect(trace).to have_content('This is secret')
        end
      end

      private

      def add_file_variable_to_project(key, value)
        create(:ci_variable, project: project, key: key, value: value, variable_type: 'file')
      end

      def wait_for_pipeline
        Support::Waiter.wait_until(max_duration: 300, sleep_interval: 10,
          message: 'Wait for pipeline to complete successfully') do
          pipeline = project.latest_pipeline
          if %w[failed canceled].include?(pipeline[:status])
            raise "Pipeline did not succeed, got status: #{pipeline[:status]}"
          end

          pipeline[:status] == 'success'
        end
      end
    end
  end
end
