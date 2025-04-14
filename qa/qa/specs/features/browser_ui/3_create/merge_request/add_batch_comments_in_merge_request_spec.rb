# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    # admin required to check if feature flag is enabled
    describe 'Batch comments in merge request', :smoke, :requires_admin, product_group: :code_review do
      let(:project) { create(:project, name: 'project-with-merge-request') }
      let(:merge_request) do
        create(:merge_request, title: 'This is a merge request', description: 'Great feature', project: project)
      end

      it 'user submits a non-diff review',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347777',
        feature_flag: { name: :improved_review_experience } do
        skip('improved_review_experience FF is WIP') if Runtime::Feature.enabled?('improved_review_experience')

        Flow::Login.sign_in

        merge_request.visit!

        Page::MergeRequest::Show.perform do |show|
          show.start_review_with_comment('new comment to start review')
          show.add_comment_to_review('comment added to review')
          show.submit_pending_reviews

          expect(show).to have_comment('new comment to start review')
          expect(show).to have_comment('comment added to review')
          expect(show).to have_content("2 unresolved threads")
        end
      end

      it 'user submits a diff review',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347778',
        feature_flag: { name: :improved_review_experience } do
        skip('improved_review_experience FF is WIP') if Runtime::Feature.enabled?('improved_review_experience')

        Flow::Login.sign_in

        merge_request.visit!

        Page::MergeRequest::Show.perform do |show|
          show.click_diffs_tab
          show.add_comment_to_diff("Can you check this line of code?")
          show.start_review
          show.submit_pending_reviews
        end

        # Overwrite the added file to create a system note as required to
        # trigger the bug described here: https://gitlab.com/gitlab-org/gitlab/issues/32157
        commit_message = 'Update file'
        create(:commit,
          project: project,
          commit_message: commit_message,
          branch: merge_request.source_branch, actions: [
            { action: 'update', file_path: merge_request.file_name, content: "File updated" }
          ])
        project.wait_for_push(commit_message)

        Page::MergeRequest::Show.perform do |show|
          show.click_discussions_tab
          show.resolve_discussion_at_index(0)

          expect(show).to have_comment("Can you check this line of code?")
          expect(show).to have_content("All threads resolved")
        end
      end
    end
  end
end
