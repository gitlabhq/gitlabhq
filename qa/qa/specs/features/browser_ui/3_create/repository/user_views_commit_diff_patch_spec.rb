# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Commit data', product_group: :source_code do
      let(:user) { Runtime::User::Store.test_user }
      let(:project) { create(:project, :with_readme) }
      let(:commit_message) { 'Add second file' }

      before do
        create(:file,
          project: project,
          name: 'second',
          content: 'second file content',
          commit_message: commit_message)

        Flow::Login.sign_in

        project.visit!

        Page::Project::Show.perform do |show|
          show.click_commit(commit_message)
        end
      end

      it 'user views raw email patch', :skip_live_env,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347755' do
        Page::Project::Commit::Show.perform(&:select_email_patches)

        expect(page).to have_content(/From: "?#{Regexp.escape(user.name)}"? <#{user.commit_email}>/)
        expect(page).to have_content('Subject: [PATCH] Add second file')
        expect(page).to have_content('diff --git a/second b/second')
      end

      it 'user views raw commit diff', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347754' do
        Page::Project::Commit::Show.perform(&:select_plain_diff)

        expect(find('pre').text).to start_with('diff --git a/second b/second')
        expect(page).to have_content('+second file content')
      end
    end
  end
end
