# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :transient do
    describe 'Discussion comments transient bugs' do
      let(:user1) do
        Resource::User.fabricate_or_use(Runtime::Env.gitlab_qa_username_1, Runtime::Env.gitlab_qa_password_1)
      end

      let(:my_first_reply) { 'This is my first reply' }
      let(:my_second_reply) { "@#{Runtime::Env.gitlab_qa_username_1}" }
      let(:my_third_reply) { "@#{Runtime::Env.gitlab_qa_username_1} This is my third reply" }
      let(:my_fourth_reply) { '/close' }

      before do
        Flow::Login.sign_in
      end

      it 'comments with mention on a discussion in an issue', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1753' do
        Runtime::Env.transient_trials.times do |i|
          QA::Runtime::Logger.info("Transient bug test action - Trial #{i}")

          Resource::Issue.fabricate_via_api!.visit!

          Page::Project::Issue::Show.perform do |issue_page|
            issue_page.select_all_activities_filter
            issue_page.start_discussion('My first discussion')
            issue_page.reply_to_discussion(1, my_first_reply)

            expect(issue_page).to have_comment(my_first_reply)

            issue_page.reply_to_discussion(1, "#{my_second_reply}\n")

            expect(issue_page).to have_comment(my_second_reply)

            issue_page.reply_to_discussion(1, my_third_reply)

            expect(issue_page).to have_comment(my_third_reply)

            issue_page.reply_to_discussion(1, my_fourth_reply)

            expect(issue_page).to have_system_note('closed')
          end
        end
      end
    end
  end
end
