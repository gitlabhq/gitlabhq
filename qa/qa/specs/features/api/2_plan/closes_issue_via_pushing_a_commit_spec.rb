# frozen_string_literal: true

require 'airborne'

module QA
  context 'Plan' do
    include Support::Api

    describe 'Issue' do
      let(:issue) do
        Resource::Issue.fabricate_via_api!
      end

      let(:issue_id) { issue.api_response[:iid] }

      let(:api_client) { Runtime::API::Client.new(:gitlab) }

      before do
        # Initial commit should be pushed because
        # the very first commit to the project doesn't close the issue
        # https://gitlab.com/gitlab-org/gitlab-foss/issues/38965
        push_commit('Initial commit')
      end

      it 'closes via pushing a commit' do
        push_commit("Closes ##{issue_id}", false)

        Support::Retrier.retry_until(max_duration: 10, sleep_interval: 1) do
          issue_closed?
        end
      end

      private

      def push_commit(commit_message, new_branch = true)
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.commit_message = commit_message
          push.new_branch = new_branch
          push.file_content = commit_message
          push.project = issue.project
        end
      end

      def issue_closed?
        response = get Runtime::API::Request.new(api_client, "/projects/#{issue.project.id}/issues/#{issue_id}").url
        parse_body(response)[:state] == 'closed'
      end
    end
  end
end
