# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'Commit data' do
      before(:context) do
        # Get the user's details to confirm they're included in the email patch
        @user = Resource::User.fabricate_via_api! do |user|
          user.username = Runtime::User.username
        end

        project_push = Resource::Repository::ProjectPush.fabricate! do |push|
          push.file_name = 'README.md'
          push.file_content = '# This is a test project'
          push.commit_message = 'Add README.md'
        end
        @project = project_push.project

        # first file added has no parent commit, thus no diff data
        # add second file to repo to enable diff from initial commit
        @commit_message = 'Add second file'

        Resource::File.fabricate_via_api! do |file|
          file.project = @project
          file.name = 'second'
          file.content = 'second file content'
          file.commit_message = @commit_message
          file.author_name = @user.name
          file.author_email = @user.public_email
        end
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

      it 'user views raw email patch' do
        view_commit

        Page::Project::Commit::Show.perform(&:select_email_patches)

        expect(page).to have_content(/From: "?#{Regexp.escape(@user.name)}"? <#{@user.public_email}>/)
        expect(page).to have_content('Subject: [PATCH] Add second file')
        expect(page).to have_content('diff --git a/second b/second')
      end

      it 'user views raw commit diff' do
        view_commit

        Page::Project::Commit::Show.perform(&:select_plain_diff)

        expect(raw_content).to start_with('diff --git a/second b/second')
        expect(page).to have_content('+second file content')
      end
    end
  end
end
