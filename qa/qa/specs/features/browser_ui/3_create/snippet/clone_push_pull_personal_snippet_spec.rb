# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Version control for personal snippets' do
      let(:new_file) { 'new_snippet_file' }
      let(:changed_content) { 'changes' }
      let(:commit_message) { 'Changes to snippets' }
      let(:added_content) { 'updated ' }

      let(:snippet) do
        Resource::Snippet.fabricate! do |snippet|
          snippet.file_name = new_file
        end
      end

      let(:ssh_key) do
        Resource::SSHKey.fabricate_via_api! do |resource|
          resource.title = "my key title #{Time.now.to_f}"
        end
      end

      let(:repository_uri_http) do
        snippet.visit!
        Page::Dashboard::Snippet::Show.perform(&:get_repository_uri_http)
      end

      let(:repository_uri_ssh) do
        ssh_key
        snippet.visit!
        Page::Dashboard::Snippet::Show.perform(&:get_repository_uri_ssh)
      end

      before do
        Flow::Login.sign_in
      end

      after do
        ssh_key.remove_via_api!
      end

      it 'clones, pushes, and pulls a snippet over HTTP, edits via UI', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1748' do
        push = Resource::Repository::Push.fabricate! do |push|
          push.repository_http_uri = repository_uri_http
          push.file_name = new_file
          push.file_content = changed_content
          push.commit_message = commit_message
          push.new_branch = false
        end

        page.refresh
        verify_changes_in_ui

        Page::Dashboard::Snippet::Show.perform(&:click_edit_button)

        Page::Dashboard::Snippet::Edit.perform do |snippet|
          snippet.add_to_file_content(added_content)
          snippet.save_changes
        end

        Git::Repository.perform do |repository|
          repository.init_repository
          repository.pull(repository_uri_http, push.branch_name)

          expect(repository.commits.size).to eq(3)
          expect(repository.commits.first).to include('Update snippet')
          expect(repository.file_content(new_file)).to include("#{added_content}#{changed_content}")
        end

        snippet.remove_via_api!
      end

      it 'clones, pushes, and pulls a snippet over SSH, deletes via UI', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1747' do
        push = Resource::Repository::Push.fabricate! do |push|
          push.repository_ssh_uri = repository_uri_ssh
          push.ssh_key = ssh_key
          push.file_name = new_file
          push.file_content = changed_content
          push.commit_message = commit_message
          push.new_branch = false
        end

        page.refresh
        verify_changes_in_ui

        Page::Dashboard::Snippet::Show.perform(&:click_delete_button)

        # attempt to pull a deleted snippet, get a missing repository error
        Git::Repository.perform do |repository|
          repository.uri = repository_uri_ssh
          repository.use_ssh_key(ssh_key)
          repository.init_repository

          expect { repository.pull(repository_uri_ssh, push.branch_name) }
            .to raise_error(QA::Support::Run::CommandError, /fatal: Could not read from remote repository\./)
        end
      end

      def verify_changes_in_ui
        Page::Dashboard::Snippet::Show.perform do |snippet|
          expect(snippet).to have_file_name(new_file)
          expect(snippet).to have_file_content(changed_content)
        end
      end
    end
  end
end
