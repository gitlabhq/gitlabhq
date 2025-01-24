# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_authoring do
    describe 'Pipeline with image:pull_policy' do
      let(:runner_name) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
      let(:job_name) { "test-job-#{pull_policies.join('-')}" }
      let(:project) { create(:project, name: 'pipeline-with-image-pull-policy') }
      let!(:runner) do
        create(:project_runner,
          project: project,
          name: runner_name,
          tags: [runner_name],
          executor: :docker)
      end

      before do
        Flow::Login.sign_in
        update_runner_policy(allowed_policies)
        add_ci_file

        project.visit_latest_pipeline
      end

      after do
        runner.remove_via_api!
      end

      context 'when policy is allowed', quarantine: {
        type: :flaky,
        issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/504929'
      } do
        let(:allowed_policies) { %w[if-not-present always never] }

        where do
          {
            'with [always] policy' => {
              pull_policies: %w[always],
              pull_image: true,
              message: 'Pulling docker image ruby:latest',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/367154'
            },
            'with [always if-not-present] policies' => {
              pull_policies: %w[always if-not-present],
              pull_image: true,
              message: 'Pulling docker image ruby:latest',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/368857'
            },
            'with [if-not-present] policy' => {
              pull_policies: %w[if-not-present],
              pull_image: true,
              message: 'Using locally found image version due to "if-not-present" pull policy',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/368858'
            },
            'with [never] policy' => {
              pull_policies: %w[never],
              pull_image: false,
              message: 'Pulling docker image ruby:latest',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/368859'
            }
          }
        end

        with_them do
          it 'applies pull policy in job correctly', testcase: params[:testcase] do
            project.visit_job(job_name)

            if pull_image
              expect(job_log).to have_content(message),
                "Expected to find #{message} in #{job_log}, but didn't."
            else
              expect(job_log).not_to have_content(message),
                "Found #{message} in #{job_log}, but didn't expect to."
            end
          end
        end
      end

      context 'when policy is not allowed' do
        let(:allowed_policies) { %w[never] }
        let(:pull_policies) { %w[always] }

        # The sentence seems differ from time to time,
        # only checking portions of the sentence that matter
        let(:text1) { 'pull_policy ([always])' }
        let(:text2) { 'is not one of the allowed_pull_policies ([never])' }

        it(
          'fails job with policy not allowed message', :smoke,
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/368853',
          quarantine: {
            type: :flaky,
            issue: "https://gitlab.com/gitlab-org/gitlab/-/issues/462232"
          }
        ) do
          project.visit_job(job_name)

          expect(job_log).to include(text1, text2),
            "Expected to find contents #{text1} and #{text2} in #{job_log}, but didn't."
        end
      end

      private

      def update_runner_policy(allowed_policies)
        Runtime::Logger.info('Updating runner config to allow pull policies...')

        # Copy config.toml file from docker to local
        # Update local file with allowed_pull_policies config
        # Copy file with new content back to docker
        tempdir = Tempfile.new('config.toml')
        QA::Service::Shellout.shell("docker cp #{runner_name}:/etc/gitlab-runner/config.toml #{tempdir.path}")

        File.open(tempdir.path, 'a') do |f|
          f << %(    allowed_pull_policies = #{allowed_policies}\n)
        end

        QA::Service::Shellout.shell("docker cp #{tempdir.path} #{runner_name}:/etc/gitlab-runner/config.toml")

        tempdir.close!

        runner.restart
      end

      def add_ci_file
        create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
          {
            action: 'create',
            file_path: '.gitlab-ci.yml',
            content: <<~YAML
              default:
                image: ruby:latest
                tags: [#{runner_name}]

              #{job_name}:
                script: echo "Using pull policies #{pull_policies}"
                image:
                  name: ruby:latest
                  pull_policy: #{pull_policies}
            YAML
          }
        ])

        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
        Flow::Pipeline.wait_for_latest_pipeline_to_have_status(project: project, status: 'success')
      end

      def job_log
        Page::Project::Job::Show.perform(&:output)
      end
    end
  end
end
