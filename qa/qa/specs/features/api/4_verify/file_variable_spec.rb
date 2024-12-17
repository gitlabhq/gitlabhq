# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_authoring do
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
        'does not expose file variable content with echo', :smoke,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/370791'
      ) do
        job = create(:job, project: project, id: project.job_by_name('job_echo')[:id])

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
        job = create(:job, project: project, id: project.job_by_name('job_cat')[:id])

        aggregate_failures do
          trace = job.trace
          expect(trace).to have_content('hello, this is test')
          expect(trace).to have_content('This is secret')
        end
      end

      private

      def add_file_variable_to_project(key, value)
        create(:ci_variable, project: project, key: key, value: value, variable_type: 'file')
      end

      def trigger_pipeline
        create(:pipeline, project: project)
      end

      def wait_for_pipeline
        Support::Waiter.wait_until do
          project.pipelines.present? && project.pipelines.first[:status] == 'success'
        end
      end
    end
  end
end
