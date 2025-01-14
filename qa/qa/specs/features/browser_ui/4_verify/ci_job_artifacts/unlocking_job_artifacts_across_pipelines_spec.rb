# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_execution do
    describe "Unlocking job artifacts across pipelines" do
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
      let(:project) { create(:project, name: 'unlock-job-artifacts-project') }
      let!(:runner) { create(:project_runner, project: project, name: executor, tags: [executor]) }

      before do
        Flow::Login.sign_in
        project.visit!
      end

      after do
        runner.remove_via_api!
      end

      context 'when latest pipeline is successful' do
        before do
          add_ci_file(job_name: 'job_1', script: 'echo test')
        end

        it 'unlocks job artifacts from previous successful pipeline',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/394807' do
          project.visit_job('job_1')
          Page::Project::Job::Show.perform do |job|
            expect(job).to have_locked_artifact
          end

          update_ci_file(job_name: 'job_2', script: 'echo test', pipeline_count: 2, status: 'success')

          project.visit_job('job_2')
          Page::Project::Job::Show.perform do |job|
            expect(job).to have_locked_artifact
          end

          project.visit_job('job_1')
          Page::Project::Job::Show.perform do |job|
            expect(job).to have_unlocked_artifact
          end
        end
      end

      context 'when latest pipeline failed' do
        before do
          add_ci_file(job_name: 'successful_job_1', script: 'echo test')
        end

        it 'keeps job artifacts from latest failed pipelines and from latest successful pipeline',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/394808' do
          update_ci_file(job_name: 'failed_job_1', script: 'exit 1', pipeline_count: 2, status: 'failed')

          update_ci_file(job_name: 'failed_job_2', script: 'exit 2', pipeline_count: 3, status: 'failed')

          project.visit_job('failed_job_2')
          Page::Project::Job::Show.perform do |job|
            expect(job).to have_locked_artifact
          end

          project.visit_job('failed_job_1')
          Page::Project::Job::Show.perform do |job|
            expect(job).to have_unlocked_artifact
          end

          project.visit_job('successful_job_1')
          Page::Project::Job::Show.perform do |job|
            expect(job).to have_locked_artifact
          end
        end
      end

      context 'when latest pipeline is blocked' do
        before do
          add_ci_file(job_name: 'successful_job_1', script: 'echo test')
        end

        it 'keeps job artifacts from the latest blocked pipeline and from latest successful pipeline',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/395511' do
          update_ci_with_manual_job(job_name: 'successful_job_with_manual_1', script: 'echo test', pipeline_count: 2)

          update_ci_with_manual_job(job_name: 'successful_job_with_manual_2', script: 'echo test', pipeline_count: 3)

          project.visit_job('successful_job_with_manual_2')
          Page::Project::Job::Show.perform do |job|
            expect(job).to have_locked_artifact
          end

          project.visit_job('successful_job_with_manual_1')
          Page::Project::Job::Show.perform do |job|
            expect(job).to have_unlocked_artifact
          end

          project.visit_job('successful_job_1')
          Page::Project::Job::Show.perform do |job|
            expect(job).to have_locked_artifact
          end
        end
      end

      private

      def add_ci_file(job_name:, script:)
        create(:commit, project: project, commit_message: "Set job #{job_name} script #{script}", actions: [
          { action: 'create', **ci_file_with_job_artifact(job_name, script) }
        ])
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
        Flow::Pipeline.wait_for_latest_pipeline_to_have_status(project: project, status: 'success')
      end

      def update_ci_file(job_name:, script:, pipeline_count:, status:)
        create(:commit, project: project, commit_message: "Set job #{job_name} script #{script}", actions: [
          { action: 'update', **ci_file_with_job_artifact(job_name, script) }
        ])
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project, size: pipeline_count)
        Flow::Pipeline.wait_for_latest_pipeline_to_have_status(project: project, status: status)
      end

      def update_ci_with_manual_job(job_name:, script:, pipeline_count:)
        create(:commit, project: project, commit_message: "Set job #{job_name} script #{script}", actions: [
          { action: 'update', **ci_file_with_manual_job(job_name, script) }
        ])
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project, size: pipeline_count)
        Flow::Pipeline.wait_for_latest_pipeline_to_have_status(project: project, status: 'manual')
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
    end
  end
end
