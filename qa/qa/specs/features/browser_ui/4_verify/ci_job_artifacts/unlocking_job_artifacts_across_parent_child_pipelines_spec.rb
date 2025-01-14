# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_execution,
    quarantine: {
      issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/422863',
      type: :flaky
    } do
    describe 'Unlocking job artifacts across parent-child pipelines' do
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
      let(:project) { create(:project, name: 'unlock-job-artifacts-parent-child-project') }
      let!(:runner) { create(:project_runner, project: project, name: executor, tags: [executor]) }

      before do
        Flow::Login.sign_in
        project.visit!
      end

      after do
        runner.remove_via_api!
      end

      context 'without strategy:depend' do
        let(:strategy) { nil }

        before do
          add_parent_child_ci_files(
            parent_job_name: 'parent_1', parent_script: 'echo parent',
            child_job_name: 'child_1', child_script: 'echo child'
          )
        end

        context 'when latest pipeline family is successful' do
          before do
            update_parent_child_ci_files(
              parent_job_name: 'parent_2', parent_script: 'echo parent',
              child_job_name: 'child_2', child_script: 'echo child',
              pipeline_count: 2, status: 'success'
            )
          end

          it 'unlocks job artifacts from previous successful pipeline family', :aggregate_failures,
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/395516' do
            project.visit_job('parent_2')
            expect_job_to_have_locked_artifact

            project.visit_job('child_2')
            expect_job_to_have_locked_artifact

            project.visit_job('parent_1')
            expect_job_to_have_unlocked_artifact

            project.visit_job('child_1')
            expect_job_to_have_unlocked_artifact
          end
        end

        context 'when latest parent pipeline failed' do
          before do
            update_parent_child_ci_files(
              parent_job_name: 'parent_2', parent_script: 'exit 1',
              child_job_name: 'child_2', child_script: 'echo child',
              pipeline_count: 2, status: 'failed'
            )
          end

          it 'locks job artifacts from previous successful pipeline family', :aggregate_failures,
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396243' do
            project.visit_job('parent_2')
            expect_job_to_have_locked_artifact

            project.visit_job('child_2')
            expect_job_to_have_locked_artifact

            project.visit_job('parent_1')
            expect_job_to_have_locked_artifact

            project.visit_job('child_1')
            expect_job_to_have_locked_artifact
          end
        end

        context 'when latest child pipeline failed and latest parent is successful' do
          before do
            update_parent_child_ci_files(
              parent_job_name: 'parent_2', parent_script: 'echo parent',
              child_job_name: 'child_2', child_script: 'exit 1',
              pipeline_count: 2, status: 'success'
            )
          end

          it 'unlocks job artifacts from previous successful pipeline family', :aggregate_failures,
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396244' do
            project.visit_job('parent_2')
            expect_job_to_have_locked_artifact

            project.visit_job('child_2')
            expect_job_to_have_locked_artifact

            project.visit_job('parent_1')
            expect_job_to_have_unlocked_artifact

            project.visit_job('child_1')
            expect_job_to_have_unlocked_artifact
          end
        end
      end

      context 'with strategy:depend' do
        let(:strategy) { 'depend' }

        before do
          add_parent_child_ci_files(
            parent_job_name: 'parent_1', parent_script: 'echo parent',
            child_job_name: 'child_1', child_script: 'echo child'
          )
        end

        context 'when latest pipeline family is successful' do
          before do
            update_parent_child_ci_files(
              parent_job_name: 'parent_2', parent_script: 'echo parent',
              child_job_name: 'child_2', child_script: 'echo child',
              pipeline_count: 2, status: 'success'
            )
          end

          it 'unlocks job artifacts from previous successful pipeline family', :aggregate_failures,
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396245' do
            project.visit_job('parent_2')
            expect_job_to_have_locked_artifact

            project.visit_job('child_2')
            expect_job_to_have_locked_artifact

            project.visit_job('parent_1')
            expect_job_to_have_unlocked_artifact

            project.visit_job('child_1')
            expect_job_to_have_unlocked_artifact
          end
        end

        context 'when latest parent pipeline failed' do
          before do
            update_parent_child_ci_files(
              parent_job_name: 'parent_2', parent_script: 'exit 1',
              child_job_name: 'child_2', child_script: 'echo child',
              pipeline_count: 2, status: 'failed'
            )
          end

          it 'locks job artifacts from previous successful pipeline family', :aggregate_failures,
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396246' do
            project.visit_job('parent_2')
            expect_job_to_have_locked_artifact

            project.visit_job('child_2')
            expect_job_to_have_locked_artifact

            project.visit_job('parent_1')
            expect_job_to_have_locked_artifact

            project.visit_job('child_1')
            expect_job_to_have_locked_artifact
          end
        end

        context 'when latest child pipeline failed' do
          before do
            update_parent_child_ci_files(
              parent_job_name: 'parent_2', parent_script: 'echo parent',
              child_job_name: 'child_2', child_script: 'exit 1',
              pipeline_count: 2, status: 'failed'
            )
          end

          it 'locks job artifacts from previous successful pipeline family', :aggregate_failures,
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396248' do
            project.visit_job('parent_2')
            expect_job_to_have_locked_artifact

            project.visit_job('child_2')
            expect_job_to_have_locked_artifact

            project.visit_job('parent_1')
            expect_job_to_have_locked_artifact

            project.visit_job('child_1')
            expect_job_to_have_locked_artifact
          end
        end
      end

      private

      def update_parent_child_ci_files(
        parent_job_name:,
        parent_script:,
        child_job_name:,
        child_script:,
        pipeline_count:,
        status:
      )
        create(:commit, project: project, commit_message: 'Update parent and child pipelines CI files.', actions: [
          { action: 'update', **parent_ci_file(parent_job_name, parent_script) },
          { action: 'update', **child_ci_file(child_job_name, child_script) }
        ])
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project, size: pipeline_count)
        Flow::Pipeline.wait_for_latest_pipeline_to_have_status(project: project, status: status)
      end

      def add_parent_child_ci_files(parent_job_name:, parent_script:, child_job_name:, child_script:)
        create(:commit, project: project, commit_message: 'Add parent and child pipelines CI files.', actions: [
          { action: 'create', **parent_ci_file(parent_job_name, parent_script) },
          { action: 'create', **child_ci_file(child_job_name, child_script) }
        ])
        Flow::Pipeline.wait_for_pipeline_creation_via_api(project: project)
        Flow::Pipeline.wait_for_latest_pipeline_to_have_status(project: project, status: 'success')
      end

      def parent_ci_file(job_name, script)
        {
          file_path: '.gitlab-ci.yml',
          content: <<~YAML
            trigger-child:
              stage: test
              trigger:
                include: ".child-ci.yml"
                strategy: #{strategy}

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

      def child_ci_file(job_name, script)
        {
          file_path: '.child-ci.yml',
          content: <<~YAML
            #{job_name}:
              stage: test
              tags: ["#{executor}"]
              script: #{script}
              artifacts:
                paths: ['.child-ci.yml']
                when: always
          YAML
        }
      end

      def expect_job_to_have_locked_artifact
        Page::Project::Job::Show.perform do |job|
          expect(job).to have_locked_artifact
        end
      end

      def expect_job_to_have_unlocked_artifact
        Page::Project::Job::Show.perform do |job|
          expect(job).to have_unlocked_artifact
        end
      end
    end
  end
end
