# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_authoring do
    describe 'Trigger matrix' do
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
      let(:project) { create(:project, name: 'project-with-pipeline') }
      let!(:runner) { create(:project_runner, project: project, name: executor, tags: [executor]) }

      before do
        Flow::Login.sign_in
        add_ci_files
        project.visit_latest_pipeline
      end

      after do
        runner.remove_via_api!
      end

      it 'creates 2 trigger jobs and passes corresponding matrix variables', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348000' do
        Page::Project::Pipeline::Show.perform do |parent_pipeline|
          trigger_title1 = 'deploy: [ovh, monitoring]'
          trigger_title2 = 'deploy: [ovh, app]'

          aggregate_failures 'Creates two child pipelines' do
            expect(parent_pipeline).to have_child_pipeline(title: trigger_title1)
            expect(parent_pipeline).to have_child_pipeline(title: trigger_title2)
          end

          # Only check output of one of the child pipelines, should be sufficient
          parent_pipeline.expand_child_pipeline(title: trigger_title1)
          parent_pipeline.click_job('test_vars')
        end

        Page::Project::Job::Show.perform do |show|
          Support::Waiter.wait_until { show.successful? }

          aggregate_failures 'Job output has the correct variables' do
            expect(show.output).to have_content('ovh')
            expect(show.output).to have_content('monitoring')
          end
        end
      end

      private

      def add_ci_files
        create(:commit, project: project, commit_message: 'todo', actions: [child_ci_file, parent_ci_file])
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
        Flow::Pipeline.wait_for_latest_pipeline_to_have_status(project: project, status: 'success')
      end

      def parent_ci_file
        {
          action: 'create',
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            test:
              stage: test
              script: echo test
              tags: [#{executor}]

            deploy:
              stage: deploy
              trigger:
                include: child.yml
              parallel:
                matrix:
                  - PROVIDER: ovh
                    STACK: [monitoring, app]

          YAML
        }
      end

      def child_ci_file
        {
          action: 'create',
          file_path: 'child.yml',
          content: <<~YAML
            test_vars:
              script:
                - echo $PROVIDER
                - echo $STACK
              tags: [#{executor}]
          YAML
        }
      end
    end
  end
end
