# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_execution do
    describe 'Parent-child pipelines independent relationship' do
      let!(:project) { create(:project, name: 'pipeline-independent-relationship') }
      let!(:runner) { create(:project_runner, project: project, name: project.name, tags: [project.name]) }

      before do
        Flow::Login.sign_in
      end

      after do
        runner.remove_via_api!
      end

      it(
        'parent pipelines passes if child passes',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/358059'
      ) do
        add_ci_files(success_child_ci_file)
        project.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |parent_pipeline|
          expect(parent_pipeline).to have_child_pipeline
          expect { parent_pipeline.has_passed? }.to eventually_be_truthy
        end
      end

      it(
        'parent pipeline passes even if child fails',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/358060'
      ) do
        add_ci_files(fail_child_ci_file)
        project.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |parent_pipeline|
          expect(parent_pipeline).to have_child_pipeline
          expect { parent_pipeline.has_passed? }.to eventually_be_truthy
        end
      end

      private

      def success_child_ci_file
        {
          action: 'create',
          file_path: '.child-ci.yml',
          content: <<~YAML
            child_job:
              stage: test
              tags: ["#{project.name}"]
              script: echo "Child job done!"

          YAML
        }
      end

      def fail_child_ci_file
        {
          action: 'create',
          file_path: '.child-ci.yml',
          content: <<~YAML
            child_job:
              stage: test
              tags: ["#{project.name}"]
              script: exit 1

          YAML
        }
      end

      def parent_ci_file
        {
          action: 'create',
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            stages:
              - test
              - deploy

            job1:
              stage: test
              trigger:
                include: ".child-ci.yml"

            job2:
              stage: deploy
              tags: ["#{project.name}"]
              script: echo "parent deploy done"

          YAML
        }
      end

      def add_ci_files(child_ci_file)
        create(:commit,
          project: project,
          commit_message: 'Add parent and child pipelines CI files.',
          actions: [child_ci_file, parent_ci_file]
        )
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
      end
    end
  end
end
