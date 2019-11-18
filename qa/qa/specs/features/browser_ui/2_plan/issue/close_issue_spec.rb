# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'Close issue' do
      let(:issue_title) { 'issue title' }
      let(:commit_message) { 'Closes' }

      before do
        Flow::Login.sign_in

        issue = Resource::Issue.fabricate_via_api! do |issue|
          issue.title = issue_title
        end

        @project = issue.project
        @issue_id = issue.api_response[:iid]

        # Initial commit should be pushed because
        # the very first commit to the project doesn't close the issue
        # https://gitlab.com/gitlab-org/gitlab-foss/issues/38965
        push_commit('Initial commit')
      end

      it 'user closes an issue by pushing commit' do
        push_commit("#{commit_message} ##{@issue_id}", false)

        @project.visit!
        Page::Project::Show.perform do |show|
          show.click_commit(commit_message)
        end
        commit_sha = Page::Project::Commit::Show.perform(&:commit_sha)

        Page::Project::Menu.perform(&:click_issues)
        Page::Project::Issue::Index.perform do |index|
          index.click_closed_issues_link
          index.click_issue_link(issue_title)
        end

        Page::Project::Issue::Show.perform do |show|
          show.select_all_activities_filter
          expect(show).to have_element(:reopen_issue_button)
          expect(show).to have_content("closed via commit #{commit_sha}")
        end
      end

      def push_commit(commit_message, new_branch = true)
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.commit_message = commit_message
          push.new_branch = new_branch
          push.file_content = commit_message
          push.project = @project
        end
      end
    end
  end
end
