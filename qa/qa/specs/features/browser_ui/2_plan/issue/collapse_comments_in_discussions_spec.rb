# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', product_group: :project_management do
    describe 'collapse comments in issue discussions' do
      let(:my_first_reply) { 'My first reply' }
      let(:one_reply) { '1 reply' }
      let(:issue) { create(:issue) }

      before do
        Flow::Login.sign_in

        issue.visit!
      end

      it 'collapses and expands reply for comments in an issue', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347985' do
        Page::Project::Issue::Show.perform do |show|
          show.select_all_activities_filter
          show.start_discussion('My first discussion')
          show.reply_to_discussion(1, my_first_reply)

          show.collapse_replies
          expect(show).to have_content(one_reply)
          expect(show).not_to have_content(my_first_reply)

          show.expand_replies
          expect(show).to have_comment(my_first_reply)
          expect(show).not_to have_content(one_reply)
        end
      end
    end
  end
end
