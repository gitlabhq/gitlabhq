# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_execution do
    describe 'Run pipeline with manual jobs' do
      let(:executor) { "qa-runner-#{SecureRandom.hex(4)}" }

      let(:project) do
        create(:project, name: 'pipeline-with-manual-job', description: 'Project for pipeline with manual job')
      end

      let!(:runner) do
        Resource::ProjectRunner.fabricate! do |runner|
          runner.project = project
          runner.name = executor
          runner.tags = [executor]
        end
      end

      let!(:ci_file) do
        create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
          {
            action: 'create',
            file_path: '.gitlab-ci.yml',
            content: <<~YAML
              default:
                tags: ["#{executor}"]

              stages:
                - Stage1
                - Stage2
                - Stage3

              Prep:
                stage: Stage1
                script: exit 0
                when: manual

              Build:
                stage: Stage2
                needs: ['Prep']
                script: exit 0
                parallel: 6

              Test:
                stage: Stage3
                needs: ['Build']
                script: exit 0

              Deploy:
                stage: Stage3
                needs: ['Test']
                script: exit 0
                parallel: 6
            YAML
          }
        ])
      end

      before do
        make_sure_to_have_a_skipped_pipeline

        Flow::Login.sign_in
        project.visit!
        Flow::Pipeline.visit_latest_pipeline(status: 'Skipped')
      end

      after do
        runner&.remove_via_api!
      end

      it(
        'does not leave any job in skipped state', :reliable,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/349158'
      ) do
        Page::Project::Pipeline::Show.perform do |show|
          show.click_job_action('Prep') # Trigger pipeline manually

          show.wait_until(max_duration: 300, sleep_interval: 2, reload: false) do
            project.latest_pipeline[:status] == 'success'
          end

          aggregate_failures do
            expect(show).to have_build('Test', status: :success)

            show.click_job_dropdown('Build')
            expect(show).not_to have_skipped_job_in_group

            show.click_job_dropdown('Build') # Close Build dropdown
            show.click_job_dropdown('Deploy')
            expect(show).not_to have_skipped_job_in_group
          end
        end
      end

      private

      # Wait for first pipeline to finish and have "skipped" status
      # If it takes too long, create new pipeline and retry (2 times)
      def make_sure_to_have_a_skipped_pipeline
        attempts ||= 1
        Runtime::Logger.info('Waiting for pipeline to have status "skipped"...')
        Support::Waiter.wait_until(max_duration: 120, sleep_interval: 3, retry_on_exception: true) do
          project.latest_pipeline[:status] == 'skipped'
        end
      rescue Support::Repeater::WaitExceededError
        raise 'Failed to create skipped pipeline after 3 attempts.' unless (attempts += 1) < 4

        Runtime::Logger.debug(
          "Previous pipeline took too long to finish. Potential jobs with problems:\n#{problematic_jobs}"
        )
        Runtime::Logger.info("Triggering a new pipeline...")
        trigger_new_pipeline
        retry
      end

      def trigger_new_pipeline
        original_count = project.pipelines.length
        create(:pipeline, project: project)

        Support::Waiter.wait_until(sleep_interval: 1) { project.pipelines.length > original_count }
      end

      # We know that all the jobs in pipeline are purposely skipped
      # The pipeline should have status "skipped" almost right away after being created
      # If pipeline is held up, likely because there are some jobs that
      # doesn't have either "skipped" or "manual" status
      def problematic_jobs
        pipeline = create(:pipeline, project: project, id: project.latest_pipeline[:id])

        acceptable_statuses = %w[skipped manual]
        pipeline.jobs.select { |job| !(acceptable_statuses.include? job[:status]) }
      end
    end
  end
end
