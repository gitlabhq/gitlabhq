# frozen_string_literal: true

module QA
  # This test uses `needs:pipeline:job` to fetch artifacts from the parent pipeline.
  RSpec.describe 'Verify', feature_category: :continuous_integration do
    describe 'Parent-child pipelines dependent relationship' do
      let!(:project) { create(:project, name: 'pipelines-dependent-relationship') }
      let!(:runner) do
        create(:project_runner, project: project, name: project.name, tags: [project.name])
      end

      before do
        Flow::Login.sign_in
      end

      after do
        runner.remove_via_api!
      end

      it(
        'parent pipeline passes when child fetches parent artifacts and passes',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/358062'
      ) do
        add_ci_files(success_child_ci_file)
        project.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |parent_pipeline|
          expect(parent_pipeline).to have_child_pipeline
          expect(parent_pipeline).to have_passed
        end
      end

      it(
        'parent pipeline fails if child fails',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/358063'
      ) do
        add_ci_files(fail_child_ci_file, expected_status: 'failed')
        project.visit_latest_pipeline

        Page::Project::Pipeline::Show.perform do |parent_pipeline|
          expect(parent_pipeline).to have_child_pipeline
          expect(parent_pipeline).to have_failed
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
              needs:
                - pipeline: $PARENT_PIPELINE_ID
                  job: job1
              script:
                - cat output.txt
                - echo "Child job done!"

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
              - build
              - test
              - deploy

            default:
              tags: ["#{project.name}"]

            job1:
              stage: build
              script: echo "build success" > output.txt
              artifacts:
                paths:
                  - output.txt

            job2:
              stage: test
              variables:
                PARENT_PIPELINE_ID: $CI_PIPELINE_ID
              trigger:
                include: ".child-ci.yml"
                strategy: depend

            job3:
              stage: deploy
              script: echo "parent deploy done"

          YAML
        }
      end

      def add_ci_files(child_ci_file, expected_status: 'success')
        create(:commit, project: project, commit_message: 'Add parent and child pipelines CI files', actions: [
          child_ci_file, parent_ci_file
        ])

        wait_for_pipeline_to_complete(expected_status: expected_status)
      end

      def wait_for_pipeline_to_complete(expected_status: 'success')
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
        Flow::Pipeline.wait_for_latest_pipeline_to_finish(project: project)

        expect(project.latest_pipeline[:status]).to eq(expected_status)

        wait_for_child_pipeline_via_api
      end

      # Wait for the downstream (child) pipeline to exist via the API before asserting on the UI.
      # The pipeline graph can take a little while to render the linked pipeline, so this avoids
      # starting DOM polling before the bridge has a downstream pipeline.
      def wait_for_child_pipeline_via_api
        parent_pipeline = create(:pipeline, project: project, id: project.latest_pipeline[:id])

        Support::Waiter.wait_until(
          message: 'Wait for child pipeline to be created',
          max_duration: Flow::Pipeline::DEFAULT_WAIT,
          sleep_interval: Flow::Pipeline::WAIT_SLEEP_INTERVAL
        ) do
          parent_pipeline.downstream_pipeline_id(bridge_name: 'job2')
        rescue Resource::Errors::ResourceQueryError
          false
        end
      end
    end
  end
end
