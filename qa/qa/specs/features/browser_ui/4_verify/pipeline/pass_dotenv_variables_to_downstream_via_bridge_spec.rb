# frozen_string_literal: true

require 'faker'

module QA
  RSpec.describe 'Verify', :runner do
    describe 'Pass dotenv variables to downstream via bridge' do
      let(:executor_1) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(8)}" }
      let(:executor_2) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(8)}" }

      let(:upstream_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-pipeline-1'
        end
      end

      let(:downstream_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-pipeline-2'
        end
      end

      let!(:runner_1) do
        Resource::Runner.fabricate! do |runner|
          runner.project = upstream_project
          runner.name = executor_1
          runner.tags = [executor_1]
        end
      end

      let!(:runner_2) do
        Resource::Runner.fabricate! do |runner|
          runner.project = downstream_project
          runner.name = executor_2
          runner.tags = [executor_2]
        end
      end

      before do
        Flow::Login.sign_in
        add_ci_file(downstream_project, downstream_ci_file)
        add_ci_file(upstream_project, upstream_ci_file)
        upstream_project.visit!
        Flow::Pipeline.visit_latest_pipeline(pipeline_condition: 'success')
      end

      after do
        runner_1.remove_via_api!
        runner_2.remove_via_api!
      end

      it 'runs the pipeline with composed config', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1086' do
        Page::Project::Pipeline::Show.perform do |parent_pipeline|
          Support::Waiter.wait_until { parent_pipeline.has_child_pipeline? }
          parent_pipeline.expand_child_pipeline
          parent_pipeline.click_job('downstream_test')
        end

        Page::Project::Job::Show.perform do |show|
          expect(show).to have_passed(timeout: 360)
        end
      end

      private

      def add_ci_file(project, file)
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add config file'
          commit.add_files([file])
        end
      end

      def upstream_ci_file
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            build:
              stage: build
              tags: ["#{executor_1}"]
              script: echo "MY_VAR=hello" >> variables.env
              artifacts:
                reports:
                  dotenv: variables.env

            trigger:
              stage: deploy
              variables:
                PASSED_MY_VAR: $MY_VAR
              trigger: #{downstream_project.full_path}
          YAML
        }
      end

      def downstream_ci_file
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            downstream_test:
              stage: test
              tags: ["#{executor_2}"]
              script: '[ "$PASSED_MY_VAR" = hello ]; exit "$?"'
          YAML
        }
      end
    end
  end
end
