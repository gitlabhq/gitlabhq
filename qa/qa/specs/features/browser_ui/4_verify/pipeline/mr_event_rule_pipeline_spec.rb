# frozen_string_literal: true

module QA
  RSpec.describe 'Verify', :runner, product_group: :pipeline_authoring do
    context 'when job is configured to only run on merge_request_events' do
      let(:mr_only_job_name) { 'mr_only_job' }
      let(:non_mr_only_job_name) { 'non_mr_only_job' }
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(number: 8)}" }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'merge-request-only-job'
        end
      end

      let!(:runner) do
        Resource::ProjectRunner.fabricate! do |runner|
          runner.project = project
          runner.name = executor
          runner.tags = [executor]
        end
      end

      let!(:ci_file) do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files(
            [
              {
                file_path: '.gitlab-ci.yml',
                content: <<~YAML
                  #{mr_only_job_name}:
                    tags: ["#{executor}"]
                    script: echo 'OK'
                    rules:
                      - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
                  #{non_mr_only_job_name}:
                    tags: ["#{executor}"]
                    script: echo 'OK'
                    rules:
                      - if: '$CI_PIPELINE_SOURCE != "merge_request_event"'
                YAML
              }
            ]
          )
        end
      end

      let(:merge_request) do
        Resource::MergeRequest.fabricate_via_api! do |merge_request|
          merge_request.project = project
          merge_request.description = Faker::Lorem.sentence
          merge_request.target_new_branch = false
          merge_request.file_name = 'new.txt'
          merge_request.file_content = Faker::Lorem.sentence
        end
      end

      before do
        Flow::Login.sign_in
        # TODO: We should remove (wait) revisiting logic when
        # https://gitlab.com/gitlab-org/gitlab/-/issues/385332 is resolved
        Support::Waiter.wait_until do
          merge_request.visit!
          Page::MergeRequest::Show.perform(&:click_pipeline_link)
          Page::Project::Pipeline::Show.perform(&:has_merge_request_badge_tag?)
        end
      end

      after do
        runner.remove_via_api!
      end

      it 'only runs the job configured to run on merge requests', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347662' do
        Page::Project::Pipeline::Show.perform do |pipeline|
          aggregate_failures do
            expect(pipeline).to have_job(mr_only_job_name)
            expect(pipeline).to have_no_job(non_mr_only_job_name)
          end
        end
      end
    end
  end
end
