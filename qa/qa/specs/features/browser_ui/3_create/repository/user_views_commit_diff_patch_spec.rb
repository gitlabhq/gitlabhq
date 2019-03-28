# frozen_string_literal: true

module QA
  context 'Create' do
    # failure reported: https://gitlab.com/gitlab-org/quality/nightly/issues/42
    # also failing in staging until the fix is picked into the next release:
    #  https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/24533
    describe 'Commit data', :quarantine do
      before(:context) do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        project_push = Resource::Repository::ProjectPush.fabricate! do |push|
          push.file_name = 'README.md'
          push.file_content = '# This is a test project'
          push.commit_message = 'Add README.md'
        end
        @project = project_push.project

        # first file added has no parent commit, thus no diff data
        # add second file to repo to enable diff from initial commit
        @commit_message = 'Add second file'

        Page::Project::Show.perform(&:create_new_file!)
        Page::File::Form.perform do |f|
          f.add_name('second')
          f.add_content('second file content')
          f.add_commit_message(@commit_message)
          f.commit_changes
        end
      end

      def view_commit
        @project.visit!
        Page::Project::Show.perform do |page|
          page.click_commit(@commit_message)
        end
      end

      def raw_content
        find('pre').text
      end

      it 'user views raw email patch' do
        user = Resource::User.fabricate_via_api! do |user|
          user.username = Runtime::User.username
        end

        view_commit

        Page::Project::Commit::Show.perform(&:select_email_patches)

        expect(page).to have_content("From: #{user.name} <#{user.public_email}>")
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
