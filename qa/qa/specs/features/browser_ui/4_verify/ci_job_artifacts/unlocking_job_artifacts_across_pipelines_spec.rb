# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_security do
    describe "Unlocking job artifacts across pipelines" do
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'unlock-job-artifacts-project'
        end
      end

      let!(:runner) do
        Resource::ProjectRunner.fabricate! do |runner|
          runner.project = project
          runner.name = executor
          runner.tags = [executor]
        end
      end

      before do
        Flow::Login.sign_in
        project.visit!
      end

      context 'when latest pipeline is successful' do
        before do
          add_ci_file(job_name: 'job_1', script: 'echo test')
          Flow::Pipeline.wait_for_latest_pipeline(status: 'passed')
        end

        it 'unlocks job artifacts from previous successful pipeline',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/394807' do
          find_job('job_1').visit!
          Page::Project::Job::Show.perform do |job|
            expect(job).to have_locked_artifact
          end

          update_ci_file(job_name: 'job_2', script: 'echo test')

          Flow::Pipeline.wait_for_latest_pipeline(status: 'passed')

          find_job('job_2').visit!
          Page::Project::Job::Show.perform do |job|
            expect(job).to have_locked_artifact
          end

          find_job('job_1').visit!
          Page::Project::Job::Show.perform do |job|
            expect(job).to have_unlocked_artifact
          end
        end
      end

      context 'when latest pipeline failed' do
        before do
          add_ci_file(job_name: 'successful_job_1', script: 'echo test')
          Flow::Pipeline.wait_for_latest_pipeline(status: 'passed')
        end

        it 'keeps job artifacts from latest failed pipelines and from latest successful pipeline',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/394808',
          quarantine: {
            issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/266958',
            type: :bug
          } do
          update_ci_file(job_name: 'failed_job_1', script: 'exit 1')
          Flow::Pipeline.wait_for_latest_pipeline(status: 'failed')

          update_ci_file(job_name: 'failed_job_2', script: 'exit 2')
          Flow::Pipeline.wait_for_latest_pipeline(status: 'failed')

          find_job('failed_job_2').visit!
          Page::Project::Job::Show.perform do |job|
            expect(job).to have_locked_artifact
          end

          find_job('failed_job_1').visit!
          Page::Project::Job::Show.perform do |job|
            expect(job).to have_unlocked_artifact
          end

          find_job('successful_job_1').visit!
          Page::Project::Job::Show.perform do |job|
            expect(job).to have_locked_artifact
          end
        end
      end

      context 'when latest pipeline is blocked' do
        before do
          add_ci_file(job_name: 'successful_job_1', script: 'echo test')
          Flow::Pipeline.wait_for_latest_pipeline(status: 'passed')
        end

        it 'keeps job artifacts from the latest blocked pipeline and from latest successful pipeline',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/395511',
          quarantine: {
            issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/387087',
            type: :bug
          } do
          update_ci_with_manual_job(job_name: 'successful_job_with_manual_1', script: 'echo test')
          Flow::Pipeline.wait_for_latest_pipeline(status: 'blocked')

          update_ci_with_manual_job(job_name: 'successful_job_with_manual_2', script: 'echo test')
          Flow::Pipeline.wait_for_latest_pipeline(status: 'blocked')

          find_job('successful_job_with_manual_2').visit!
          Page::Project::Job::Show.perform do |job|
            expect(job).to have_locked_artifact
          end

          find_job('successful_job_with_manual_1').visit!
          Page::Project::Job::Show.perform do |job|
            expect(job).to have_unlocked_artifact
          end

          find_job('successful_job_1').visit!
          Page::Project::Job::Show.perform do |job|
            expect(job).to have_locked_artifact
          end
        end
      end

      private

      def add_ci_file(job_name:, script:)
        ci_file = ci_file_with_job_artifact(job_name, script)

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = "Set job #{job_name} script #{script}"
          commit.add_files([ci_file])
        end
      end

      def update_ci_file(job_name:, script:)
        ci_file = ci_file_with_job_artifact(job_name, script)

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = "Set job #{job_name} script #{script}"
          commit.update_files([ci_file])
        end
      end

      def update_ci_with_manual_job(job_name:, script:)
        ci_file = ci_file_with_manual_job(job_name, script)

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = "Set job #{job_name} script #{script}"
          commit.update_files([ci_file])
        end
      end

      def ci_file_with_job_artifact(job_name, script)
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            #{job_name}:
              stage: test
              tags: ["#{executor}"]
              script: #{script}
              artifacts:
                paths: ['.gitlab-ci.yml']
                when: always
          YAML
        }
      end

      def ci_file_with_manual_job(job_name, script)
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            #{job_name}:
              stage: test
              tags: ["#{executor}"]
              script: #{script}
              artifacts:
                paths: ['.gitlab-ci.yml']

            manual-job:
              stage: test
              tags: ["#{executor}"]
              rules:
                - when: manual
              script: "echo 'this job is manual'"
              artifacts:
                paths: ['.gitlab-ci.yml']
          YAML
        }
      end

      def find_job(job_name)
        Resource::Job.fabricate_via_api! do |job|
          job.project = project
          job.id = project.job_by_name(job_name)[:id]
        end
      end
    end
  end
end
