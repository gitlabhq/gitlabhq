# frozen_string_literal: true

require 'faker'

module QA
  RSpec.describe 'Verify', :runner do
    describe 'Pass dotenv variables to downstream via bridge' do
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(8)}" }
      let(:upstream_var) { Faker::Alphanumeric.alphanumeric(8) }
      let(:group) { Resource::Group.fabricate_via_api! }

      let(:upstream_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.group = group
          project.name = 'upstream-project-with-bridge'
        end
      end

      let(:downstream_project) do
        Resource::Project.fabricate_via_api! do |project|
          project.group = group
          project.name = 'downstream-project-with-bridge'
        end
      end

      let!(:runner) do
        Resource::Runner.fabricate! do |runner|
          runner.name = executor
          runner.tags = [executor]
          runner.token = group.sandbox.runners_token
        end
      end

      before do
        Flow::Login.sign_in
        add_ci_file(downstream_project, downstream_ci_file)
        add_ci_file(upstream_project, upstream_ci_file)
        upstream_project.visit!
        Flow::Pipeline.visit_latest_pipeline(pipeline_condition: 'succeeded')
      end

      after do
        runner.remove_via_api!
        group.remove_via_api!
      end

      it 'runs the pipeline with composed config', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1086' do
        Page::Project::Pipeline::Show.perform do |parent_pipeline|
          Support::Waiter.wait_until { parent_pipeline.has_child_pipeline? }
          parent_pipeline.expand_child_pipeline
          parent_pipeline.click_job('downstream_test')
        end

        Page::Project::Job::Show.perform do |show|
          expect(show).to have_passed(timeout: 360)
          expect(show.output).to have_content(upstream_var)
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
              tags: ["#{executor}"]
              script:
                - echo "DYNAMIC_ENVIRONMENT_VAR=#{upstream_var}" >> variables.env
              artifacts:
                reports:
                  dotenv: variables.env

            trigger:
              stage: deploy
              variables:
                PASSED_MY_VAR: $DYNAMIC_ENVIRONMENT_VAR
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
              tags: ["#{executor}"]
              script:
                - echo $PASSED_MY_VAR
          YAML
        }
      end
    end
  end
end
