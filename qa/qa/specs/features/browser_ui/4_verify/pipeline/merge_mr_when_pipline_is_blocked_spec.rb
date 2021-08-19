# frozen_string_literal: true

require 'faker'

module QA
  RSpec.describe 'Verify', :runner do
    context 'When pipeline is blocked' do
      let(:executor) { "qa-runner-#{Faker::Alphanumeric.alphanumeric(8)}" }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-with-blocked-pipeline'
        end
      end

      let!(:runner) do
        Resource::Runner.fabricate! do |runner|
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
              file_path: '.gitlab-ci.yml',
              content: <<~YAML
                test_blocked_pipeline:
                  stage: build
                  tags: [#{executor}]
                  script: echo 'OK!'

                manual_job:
                  stage: test
                  needs: [test_blocked_pipeline]
                  script: echo do not click me
                  when: manual
                  allow_failure: false

                dummy_job:
                  stage: deploy
                  needs: [manual_job]
                  script: echo nothing
              YAML
            ]
          )
        end
      end

      let(:merge_request) do
        Resource::MergeRequest.fabricate_via_api! do |merge_request|
          merge_request.project = project
          merge_request.description = Faker::Lorem.sentence
          merge_request.target_new_branch = false
          merge_request.file_name = 'custom_file.txt'
          merge_request.file_content = Faker::Lorem.sentence
        end
      end

      before do
        Flow::Login.sign_in
        merge_request.visit!
      end

      after do
        runner.remove_via_api!
      end

      it 'can still merge MR successfully', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/971' do
        Page::MergeRequest::Show.perform do |show|
          # waiting for manual action status shows status badge 'blocked' on pipelines page
          show.has_pipeline_status?('waiting for manual action')
          show.merge!

          expect(show).to be_merged
        end
      end
    end
  end
end
