# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Commit data', :reliable, product_group: :source_code do
      before(:context) do
        # Get the user's details to confirm they're included in the email patch
        @user = create(:user, username: Runtime::User.username)

        project_push = Resource::Repository::ProjectPush.fabricate! do |push|
          push.file_name = 'README.md'
          push.file_content = '# This is a test project'
          push.commit_message = 'Add README.md'
        end
        @project = project_push.project

        # first file added has no parent commit, thus no diff data
        # add second file to repo to enable diff from initial commit
        @commit_message = 'Add second file'

        create(:file,
          project: @project,
          name: 'second',
          content: 'second file content',
          commit_message: @commit_message,
          author_name: @user.name,
          author_email: @user.public_email)
      end

      def view_commit
        Flow::Login.sign_in

        @project.visit!
        Page::Project::Show.perform do |show|
          show.click_commit(@commit_message)
        end
      end

      def raw_content
        find('pre').text
      end

      it 'user views raw email patch', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347755' do
        view_commit

        Page::Project::Commit::Show.perform(&:select_email_patches)

        expect(page).to have_content(/From: "?#{Regexp.escape(@user.name)}"? <#{@user.public_email}>/)
        expect(page).to have_content('Subject: [PATCH] Add second file')
        expect(page).to have_content('diff --git a/second b/second')
      end

      it 'user views raw commit diff', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347754' do
        view_commit

        Page::Project::Commit::Show.perform(&:select_plain_diff)

        expect(raw_content).to start_with('diff --git a/second b/second')
        expect(page).to have_content('+second file content')
      end
    end
  end
end
