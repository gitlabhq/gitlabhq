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

      let(:test_job_name) { 'test-job' }

      before do
        Flow::Login.sign_in
      end

      context 'when latest pipeline is successful' do
        it 'unlocks job artifacts from previous successful pipeline',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/394807' do
          add_ci_file
          project.visit!

          previous_successful_pipeline = Resource::Pipeline.fabricate! do |pipeline|
            pipeline.project = project
          end

          Flow::Pipeline.visit_latest_pipeline(status: 'passed')
          Flow::Pipeline.visit_pipeline_job_page(job_name: test_job_name)

          Page::Project::Job::Show.perform do |job|
            expect(job).to have_locked_artifact
          end

          update_ci_script('echo bye')
          project.visit!

          Flow::Pipeline.visit_latest_pipeline(status: 'passed')
          Flow::Pipeline.visit_pipeline_job_page(job_name: test_job_name)

          Page::Project::Job::Show.perform do |job|
            expect(job).to have_locked_artifact
          end

          Flow::Pipeline.visit_pipeline_job_page(pipeline: previous_successful_pipeline, job_name: test_job_name)

          Page::Project::Job::Show.perform do |job|
            expect(job).to have_unlocked_artifact
          end
        end
      end

      context 'when latest pipeline failed' do
        it 'unlocks job artifacts from failed pipelines, keeps job artifacts from latest successful pipeline',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/394808',
          quarantine: {
            issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/266958',
            type: :bug
          } do
          add_ci_file
          project.visit!

          successful_pipeline = Resource::Pipeline.fabricate! do |pipeline|
            pipeline.project = project
          end

          Flow::Pipeline.visit_latest_pipeline(status: 'passed')
          Flow::Pipeline.visit_pipeline_job_page(job_name: test_job_name)

          Page::Project::Job::Show.perform do |job|
            expect(job).to have_locked_artifact
          end

          update_ci_script('echo test && exit 1')

          failed_pipeline_1 = Resource::Pipeline.fabricate! do |pipeline|
            pipeline.project = project
          end

          Flow::Pipeline.visit_latest_pipeline(status: 'failed')
          Flow::Pipeline.visit_pipeline_job_page(job_name: test_job_name)

          Page::Project::Job::Show.perform do |job|
            expect(job).to have_unlocked_artifact
          end

          update_ci_script('echo bye && exit 1')
          project.visit!

          Flow::Pipeline.visit_latest_pipeline(status: 'failed')
          Flow::Pipeline.visit_pipeline_job_page(job_name: test_job_name)

          Page::Project::Job::Show.perform do |job|
            expect(job).to have_unlocked_artifact
          end

          Flow::Pipeline.visit_pipeline_job_page(pipeline: failed_pipeline_1, job_name: test_job_name)

          Page::Project::Job::Show.perform do |job|
            expect(job).to have_unlocked_artifact
          end

          Flow::Pipeline.visit_pipeline_job_page(pipeline: successful_pipeline, job_name: test_job_name)

          Page::Project::Job::Show.perform do |job|
            expect(job).to have_locked_artifact
          end
        end
      end

      private

      def add_ci_file
        script = 'echo test'
        ci_file = ci_file_with_job_artifact(script)

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = "Set script #{script}"
          commit.add_files([ci_file])
        end
      end

      def update_ci_script(script)
        ci_file = ci_file_with_job_artifact(script)

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = "Set script #{script}"
          commit.update_files([ci_file])
        end
      end

      def add_failing_ci_file
        ci_file = ci_file_with_job_artifact('echo test && exit 1')

        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add failing CI file.'
          commit.add_files([ci_file])
        end
      end

      def ci_file_with_job_artifact(script)
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            #{test_job_name}:
              stage: test
              tags: ["#{executor}"]
              script: #{script}
              artifacts:
                paths: ['.gitlab-ci.yml']
                when: always
          YAML
        }
      end
    end
  end
end
