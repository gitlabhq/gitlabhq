# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_execution do
    describe 'Job artifacts' do
      context 'when exposed' do
        let(:total_jobs_count) { 3 }
        let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }
        let(:project) { create(:project, name: 'project-with-artifacts', initialize_with_readme: true) }
        let!(:runner) { create(:project_runner, project: project, name: executor, tags: [executor]) }

        let!(:commit_ci_file) do
          create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
            { action: 'create', file_path: '.gitlab-ci.yml', content: content }
          ])
        end

        let(:merge_request) do
          create(:merge_request,
            project: project,
            description: 'Simple MR for a simple test',
            target_new_branch: false,
            file_name: 'new_file.txt',
            file_content: 'Simple file for a simple MR')
        end

        before do
          create_mr
          Flow::Login.sign_in

          merge_request.visit!
        end

        after do
          runner.remove_via_api!
        end

        it 'show up in MR widget', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/426999' do
          Page::MergeRequest::Show.perform do |show|
            Support::Waiter.wait_until(reload_page: false) do
              show.has_pipeline_status?('passed')
            end

            show.click_artifacts_dropdown_button

            aggregate_failures do
              (1..total_jobs_count).each do |i|
                expect(show).to have_artifact_with_name("job_with_artifact_#{i}")
              end
            end

            show.click_artifacts_dropdown_button # dismiss the dropdown
            show.open_exposed_artifacts_list

            aggregate_failures do
              (1..total_jobs_count).each do |i|
                expect(show).to have_exposed_artifact_with_name("artifact_#{i}")
              end
            end
          end
        end
      end

      private

      def content
        (1..total_jobs_count).map do |i|
          <<~YAML
            job_with_artifact_#{i}:
              tags: ["#{executor}"]
              script:
                - mkdir tmp
                - echo "write some random strings #{i} times" >> tmp/file_#{i}.xml
              artifacts:
                expose_as: 'artifact #{i}'
                paths:
                  - tmp/
          YAML
        end.join("\n")
      end

      def create_mr
        merge_request

        Support::Waiter.wait_until(message: 'Wait for mr pipeline to be created', max_duration: 180) do
          project.pipelines.length > 1
        end
      end
    end
  end
end
