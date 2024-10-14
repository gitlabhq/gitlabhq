# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :transient, product_group: :project_management do
    describe 'Discussion comments transient bugs' do
      let(:user1) { create(:user) }

      let(:my_first_reply) { 'This is my first reply' }
      let(:my_second_reply) { "@#{Runtime::Env.gitlab_qa_username_1}" }
      let(:my_third_reply) { "@#{Runtime::Env.gitlab_qa_username_1} This is my third reply" }
      let(:my_fourth_reply) { '/close' }

      before do
        Flow::Login.sign_in
      end

      after do
        user1.remove_via_api!
      end

      it 'comments with mention on a discussion in an issue', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347940' do
        Runtime::Env.transient_trials.times do |i|
          QA::Runtime::Logger.info("Transient bug test action - Trial #{i}")

          create(:issue).visit!

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
