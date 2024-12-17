# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_execution do
    describe 'Project artifacts' do
      context 'when user tries bulk deletion' do
        let(:total_jobs_count) { 20 }
        let(:total_runners_count) { 5 }
        let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
        let(:project) { create(:project, name: 'project-with-many-artifacts') }
        let(:runners) { [] }

        before do
          launch_runners
          commit_ci_file
          Flow::Login.sign_in
          wait_for_pipeline_to_succeed

          project.visit!
          Page::Project::Menu.perform(&:go_to_artifacts)
          Page::Project::Artifacts::Index.perform(&:select_all)
        end

        after do
          Parallel.each((0..(total_runners_count - 1)), in_threads: 1) do |i|
            runners[i]&.remove_via_api!
          end
        end

        it 'successfully delete them',
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/425725' do
          Page::Project::Artifacts::Index.perform do |index|
            index.delete_selected_artifacts

            expect(index).to have_no_artifacts
          end
        end
      end

      private

      def launch_runners
        Parallel.each((1..total_runners_count), in_threads: 1) do |i|
          runners << create(:project_runner, project: project, name: "#{executor}-#{i}", tags: [executor])
        end
      end

      def commit_ci_file
        create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
          { action: 'create', file_path: '.gitlab-ci.yml', content: content }
        ])
      end

      def content
        (1..total_jobs_count).map do |i|
          <<~YAML
            job_with_artifact_#{i}:
              tags: ["#{executor}"]
              script:
                - mkdir tmp
                - echo "write some random strings #{i} times" >> tmp/file_#{i}.xml
              artifacts:
                paths:
                  - tmp
          YAML
        end.join("\n")
      end

      def wait_for_pipeline_to_succeed
        Support::Waiter.wait_until(message: 'Wait for pipeline to succeed', max_duration: 300) do
          project.latest_pipeline.present? && project.latest_pipeline[:status] == 'success'
        end
      end
    end
  end
end
