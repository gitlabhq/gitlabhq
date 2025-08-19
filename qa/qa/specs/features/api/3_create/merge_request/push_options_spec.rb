# frozen_string_literal: true

module QA
  RSpec.describe 'Create', feature_category: :code_review_workflow do
    describe 'Merge request push options', :smoke do
      # If run locally on GDK, push options need to be enabled on the host with the following command:
      #
      # git config --global receive.advertisepushoptions true

      let(:project) { create(:project, :with_readme) }
      let(:branch) { "push-options-test-#{SecureRandom.hex(8)}" }
      let(:title) { "MR push options test #{SecureRandom.hex(8)}" }
      let(:commit_message) { 'Add README.md' }
      let(:description) { "This is a test of MR push options" }

      let(:target_branch) do
        create(:branch, name: "push-options-test-target-#{SecureRandom.hex(8)}", project: project,
          ref: project.default_branch)
      end

      before do
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.commit_message = commit_message
          push.branch_name = branch
          push.merge_request_push_options = {
            create: true,
            title: title,
            label: %w[one two three],
            target: target_branch.name,
            description: description
          }
        end
      end

      it 'sets merge request details', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347839' do
        merge_request = project.merge_request_with_title(title)

        aggregate_failures do
          expect(merge_request).not_to be_nil, "There was a problem creating the merge request"
          expect(merge_request[:labels]).to include('one').and include('two').and include('three')
          expect(merge_request[:target_branch]).to eq(target_branch.name)
          expect(merge_request[:title]).to eq(title)
          expect(merge_request[:description]).to eq(description)
        end
      end

      it 'removes labels on subsequent push',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347840' do
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.file_content = "Unlabel test #{SecureRandom.hex(8)}"
          push.commit_message = commit_message
          push.branch_name = branch
          push.new_branch = false
          push.merge_request_push_options = {
            title: title,
            unlabel: %w[one three]
          }
        end

        merge_request = project.merge_request_with_title(title)

        expect(merge_request).not_to be_nil, "There was a problem creating the merge request"

        aggregate_failures do
          expect(merge_request[:labels]).to include('two')
          expect(merge_request[:labels]).not_to include('one')
          expect(merge_request[:labels]).not_to include('three')
        end
      end
    end
  end
end
