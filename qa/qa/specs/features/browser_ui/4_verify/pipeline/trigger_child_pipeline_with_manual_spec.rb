# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_execution do
    describe "Trigger child pipeline with 'when:manual'" do
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

      it 'can trigger bridge job',
        quarantine: {
          only: { job: 'gdk-instance' },
          issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/461957',
          type: :test_environment
        },
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/348086' do
        Page::Project::Pipeline::Show.perform do |parent_pipeline|
          expect(parent_pipeline).not_to have_child_pipeline

          parent_pipeline.click_job_action('trigger')
          Support::Waiter.wait_until(max_duration: 240) { parent_pipeline.has_child_pipeline? }

          parent_pipeline.expand_child_pipeline
          expect(parent_pipeline).to have_build('child_build', status: nil)
        end
      end

      private

      def add_ci_files
        create(:commit, project: project, commit_message: 'Add parent and child pipelines CI files.', actions: [
          child_ci_file, parent_ci_file
        ])
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
        Flow::Pipeline.wait_for_latest_pipeline_to_have_status(project: project, status: 'success')
      end

      def parent_ci_file
        {
          action: 'create',
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            build:
              stage: build
              tags: ["#{executor}"]
              script: echo build

            trigger:
              stage: test
              when: manual
              trigger:
                include: '.child-pipeline.yml'

            deploy:
              stage: deploy
              tags: ["#{executor}"]
              script: echo deploy
          YAML
        }
      end

      def child_ci_file
        {
          action: 'create',
          file_path: '.child-pipeline.yml',
          content: <<~YAML
            child_build:
              stage: build
              tags: ["#{executor}"]
              script: echo build
          YAML
        }
      end
    end
  end
end
