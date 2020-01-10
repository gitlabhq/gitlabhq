# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'collapse comments in issue discussions' do
      let(:my_first_reply) { 'My first reply' }

      before do
        Flow::Login.sign_in

        issue = Resource::Issue.fabricate_via_api! do |issue|
          issue.title = 'issue title'
        end

        issue.visit!

        Page::Project::Issue::Show.perform do |show|
          show.select_all_activities_filter
          show.start_discussion('My first discussion')
          show.reply_to_discussion(1, my_first_reply)
        end
      end

      it 'user collapses and expands reply for comments in an issue' do
        Page::Project::Issue::Show.perform do |show|
          one_reply = "1 reply"

          show.collapse_replies
          expect(show).to have_content(one_reply)
          expect(show).not_to have_content(my_first_reply)

          show.expand_replies
          expect(show).to have_content(my_first_reply)
          expect(show).not_to have_content(one_reply)
        end
      end
    end
  end
end
