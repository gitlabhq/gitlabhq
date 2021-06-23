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

      it 'removes the source branch', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1035' do
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.branch_name = branch
          push.merge_request_push_options = {
            create: true,
            remove_source_branch: true,
            title: title
          }
        end

        merge_request = project.merge_request_with_title(title)

        expect(merge_request).not_to be_nil, "There was a problem creating the merge request"

        merge_request = Resource::MergeRequest.fabricate_via_api! do |mr|
          mr.project = project
          mr.iid = merge_request[:iid]
        end.merge_via_api!

        expect(merge_request[:state]).to eq('merged')

        # Retry in case the branch deletion takes more time to finish
        QA::Support::Retrier.retry_on_exception(max_attempts: 5, sleep_interval: 5) do
          expect(project).not_to have_branch(branch)
        end
      end
    end
  end
end
