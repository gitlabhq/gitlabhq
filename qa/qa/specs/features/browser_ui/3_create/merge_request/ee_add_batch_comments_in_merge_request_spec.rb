# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'batch comments in merge request' do
      it 'user submits, discards batch comments' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        project = Resource::Project.fabricate! do |project|
          project.name = 'project-with-merge-request'
        end

        Resource::MergeRequest.fabricate! do |merge_request|
          merge_request.title = 'This is a merge request'
          merge_request.description = 'Great feature'
          merge_request.project = project
        end

        Page::MergeRequest::Show.perform do |show_page|
          show_page.click_discussions_tab

          show_page.start_discussion("I'm starting a new discussion")
          expect(show_page).to have_content("I'm starting a new discussion")

          show_page.type_reply_to_discussion("Could you please check this?")
          show_page.comment_now
          expect(show_page).to have_content("Could you please check this?")
          expect(show_page).to have_content("0/1 discussion resolved")

          show_page.type_reply_to_discussion("Could you also check that?")
          show_page.resolve_review_discussion
          show_page.start_review
          expect(show_page).to have_content("Could you also check that?")
          expect(show_page).to have_content("Finish review 1")

          show_page.click_diffs_tab

          show_page.add_comment_to_diff("Can you check this line of code?")
          show_page.comment_now
          expect(show_page).to have_content("Can you check this line of code?")

          show_page.type_reply_to_discussion("And this syntax as well?")
          show_page.resolve_review_discussion
          show_page.start_review
          expect(show_page).to have_content("And this syntax as well?")
          expect(show_page).to have_content("Finish review 2")

          show_page.submit_pending_reviews
          expect(show_page).to have_content("2/2 discussions resolved")

          show_page.type_reply_to_discussion("Unresolving this discussion")
          show_page.unresolve_review_discussion
          show_page.comment_now
          expect(show_page).to have_content("1/2 discussions resolved")
        end

        Page::MergeRequest::Show.perform do |show_page|
          show_page.click_discussions_tab

          show_page.type_reply_to_discussion("Planning to discard this comment")
          show_page.start_review

          expect(show_page).to have_content("Finish review 1")
          show_page.discard_pending_reviews

          expect(show_page).not_to have_content("Planning to discard this comment")
        end
      end
    end
  end
end
