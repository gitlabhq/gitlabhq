# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_security,
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

      context 'without strategy:depend' do
        let(:strategy) { nil }

        before do
          add_parent_child_ci_files(
            parent_job_name: 'parent_1', parent_script: 'echo parent',
            child_job_name: 'child_1', child_script: 'echo child'
          )
          Flow::Pipeline.wait_for_latest_pipeline(status: 'Passed')
        end

        context 'when latest pipeline family is successful' do
          before do
            update_parent_child_ci_files(
              parent_job_name: 'parent_2', parent_script: 'echo parent',
              child_job_name: 'child_2', child_script: 'echo child'
            )
            Flow::Pipeline.wait_for_latest_pipeline(status: 'Passed')
          end

          it 'unlocks job artifacts from previous successful pipeline family',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/395516' do
            find_job('parent_2').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            find_job('child_2').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            find_job('parent_1').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_unlocked_artifact
            end

            find_job('child_1').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_unlocked_artifact
            end
          end
        end

        context 'when latest parent pipeline failed' do
          before do
            update_parent_child_ci_files(
              parent_job_name: 'parent_2', parent_script: 'exit 1',
              child_job_name: 'child_2', child_script: 'echo child'
            )
            Flow::Pipeline.wait_for_latest_pipeline(status: 'Failed')
          end

          it 'does not unlock job artifacts from previous successful pipeline family',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396243' do
            find_job('parent_2').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            find_job('child_2').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            find_job('parent_1').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            find_job('child_1').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end
          end
        end

        context 'when latest child pipeline failed' do
          before do
            update_parent_child_ci_files(
              parent_job_name: 'parent_2', parent_script: 'echo parent',
              child_job_name: 'child_2', child_script: 'exit 1'
            )
            Flow::Pipeline.wait_for_latest_pipeline(status: 'Passed')
          end

          it 'unlocks job artifacts from previous successful pipeline family because the latest parent is successful',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396244' do
            find_job('parent_2').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            find_job('child_2').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            find_job('parent_1').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_unlocked_artifact
            end

            find_job('child_1').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_unlocked_artifact
            end
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
          Flow::Pipeline.wait_for_latest_pipeline(status: 'Passed')
        end

        context 'when latest pipeline family is successful' do
          before do
            update_parent_child_ci_files(
              parent_job_name: 'parent_2', parent_script: 'echo parent',
              child_job_name: 'child_2', child_script: 'echo child'
            )
            Flow::Pipeline.wait_for_latest_pipeline(status: 'Passed')
          end

          it 'unlocks job artifacts from previous successful pipeline family',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396245' do
            find_job('parent_2').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            find_job('child_2').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            find_job('parent_1').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_unlocked_artifact
            end

            find_job('child_1').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_unlocked_artifact
            end
          end
        end

        context 'when latest parent pipeline failed' do
          before do
            update_parent_child_ci_files(
              parent_job_name: 'parent_2', parent_script: 'exit 1',
              child_job_name: 'child_2', child_script: 'echo child'
            )
            Flow::Pipeline.wait_for_latest_pipeline(status: 'Failed')
          end

          it 'does not unlock job artifacts from previous successful pipeline family',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396246' do
            find_job('parent_2').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            find_job('child_2').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            find_job('parent_1').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            find_job('child_1').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end
          end
        end

        context 'when latest child pipeline failed' do
          before do
            update_parent_child_ci_files(
              parent_job_name: 'parent_2', parent_script: 'echo parent',
              child_job_name: 'child_2', child_script: 'exit 1'
            )
            Flow::Pipeline.wait_for_latest_pipeline(status: 'Failed')
          end

          it 'does not unlock job artifacts from previous successful pipeline family',
            testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/396248' do
            find_job('parent_2').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            find_job('child_2').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            find_job('parent_1').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end

            find_job('child_1').visit!
            Page::Project::Job::Show.perform do |job|
              expect(job).to have_locked_artifact
            end
          end
        end
      end

      private

      def update_parent_child_ci_files(parent_job_name:, parent_script:, child_job_name:, child_script:)
        original_pipeline_count = pipeline_count

        create(:commit, project: project, commit_message: 'Update parent and child pipelines CI files.', actions: [
          { action: 'update', **parent_ci_file(parent_job_name, parent_script) },
          { action: 'update', **child_ci_file(child_job_name, child_script) }
        ])

        wait_for_pipeline_creation(original_pipeline_count)
      end

      def add_parent_child_ci_files(parent_job_name:, parent_script:, child_job_name:, child_script:)
        original_pipeline_count = pipeline_count

        create(:commit, project: project, commit_message: 'Add parent and child pipelines CI files.', actions: [
          { action: 'create', **parent_ci_file(parent_job_name, parent_script) },
          { action: 'create', **child_ci_file(child_job_name, child_script) }
        ])

        wait_for_pipeline_creation(original_pipeline_count)
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

      def find_job(job_name)
        create(:job, project: project, id: project.job_by_name(job_name)[:id])
      end

      def wait_for_pipeline_creation(original_pipeline_count)
        Support::Waiter.wait_until(sleep_interval: 1, message: 'Wait for pipeline creation') do
          pipeline_count > original_pipeline_count
        end
      end

      def pipeline_count
        project.pipelines.length
      end
    end
  end
end
