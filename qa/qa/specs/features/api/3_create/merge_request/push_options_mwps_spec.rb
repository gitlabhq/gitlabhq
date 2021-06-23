# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Merge request push options' do
      # If run locally on GDK, push options need to be enabled on the host with the following command:
      #
      # git config --global receive.advertisepushoptions true

      let(:branch) { "push-options-test-#{SecureRandom.hex(8)}" }
      let(:title) { "MR push options test #{SecureRandom.hex(8)}" }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'merge-request-push-options'
          project.initialize_with_readme = true
        end
      end

      let!(:runner) do
        Resource::Runner.fabricate! do |runner|
          runner.project = project
          runner.name = "runner-for-#{project.name}"
          runner.tags = ["runner-for-#{project.name}"]
        end
      end

      after do
        runner.remove_via_api!
      end

      it 'sets merge when pipeline succeeds', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1037' do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files(
            [
              {
                file_path: '.gitlab-ci.yml',
                content: <<~YAML
                  no-op:
                    tags:
                      - "runner-for-#{project.name}"
                    script: sleep 999 # Leave the pipeline pending
                YAML
              }
            ]
          )
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.branch_name = branch
          push.merge_request_push_options = {
            create: true,
            merge_when_pipeline_succeeds: true,
            title: title
          }
        end

        merge_request = project.merge_request_with_title(title)

        expect(merge_request).not_to be_nil, "There was a problem creating the merge request"

        merge_request = Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.project = project
          mr.iid = merge_request[:iid]
        end

        expect(merge_request.state).to eq('opened')
        expect(merge_request.merge_status).to eq('checking')
        expect(merge_request.merge_when_pipeline_succeeds).to be true
      end

      it 'merges when pipeline succeeds', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1036' do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.commit_message = 'Add .gitlab-ci.yml'
          commit.add_files(
            [
              {
                file_path: '.gitlab-ci.yml',
                content: <<~YAML
                  no-op:
                    tags:
                      - "runner-for-#{project.name}"
                    script: echo 'OK'
                YAML
              }
            ]
          )
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.branch_name = branch
          push.merge_request_push_options = {
            create: true,
            merge_when_pipeline_succeeds: true,
            title: title
          }
        end

        merge_request = project.merge_request_with_title(title)

        expect(merge_request).not_to be_nil, "There was a problem creating the merge request"
        expect(merge_request[:merge_when_pipeline_succeeds]).to be true

        merge_request = Support::Waiter.wait_until(sleep_interval: 5) do
          mr = Resource::MergeRequest.fabricate_via_api! do |mr|
            mr.project = project
            mr.iid = merge_request[:iid]
          end

          next unless mr.state == 'merged'

          mr
        end

        expect(merge_request.state).to eq('merged')
      end
    end
  end
end
