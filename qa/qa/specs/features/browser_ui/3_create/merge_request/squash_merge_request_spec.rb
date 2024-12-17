# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Merge request squashing', product_group: :code_review do
      let(:project) { create(:project, name: 'squash-before-merge') }
      let(:merge_request) { create(:merge_request, project: project, title: 'Squashing commits') }

      before do
        Flow::Login.sign_in

        # Since the test immediately navigates to the MR after pushing a commit,
        # the MR is blocked for 10 seconds
        # https://gitlab.com/gitlab-org/gitlab/-/issues/431984
        project.update_approval_configuration(reset_approvals_on_push: false)

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.commit_message = 'to be squashed'
          push.branch_name = merge_request.source_branch
          push.new_branch = false
          push.file_name = 'other.txt'
          push.file_content = "Test with unicode characters ❤✓€❄"
        end

        merge_request.visit!
      end

      it 'user squashes commits while merging', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347744' do
        Page::MergeRequest::Show.perform do |merge_request_page|
          merge_request_page.retry_on_exception(reload: true) do
            expect(merge_request_page).to have_text('to be squashed')
          end

          merge_request_page.mark_to_squash
          merge_request_page.merge!

          Git::Repository.perform do |repository|
            repository.uri = project.repository_http_location.uri
            repository.use_default_credentials
            repository.clone

            expect(repository.commits.size).to eq(3), "Expected 3 commits, got: #{repository.commits.size}"
          end
        end
      end
    end
  end
end
