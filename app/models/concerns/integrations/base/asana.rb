# frozen_string_literal: true

module Integrations
  module Base
    module Asana
      extend ActiveSupport::Concern

      PERSONAL_ACCESS_TOKEN_TEST_URL = 'https://app.asana.com/api/1.0/users/me'
      TASK_URL_TEMPLATE = 'https://app.asana.com/api/1.0/tasks/%{task_gid}'
      STORY_URL_TEMPLATE = 'https://app.asana.com/api/1.0/tasks/%{task_gid}/stories'

      class_methods do
        def title
          'Asana'
        end

        def description
          s_('AsanaService|Add commit messages as comments to Asana tasks.')
        end

        def help
          build_help_page_url(
            'user/project/integrations/asana.md',
            s_('Add commit messages as comments to Asana tasks.')
          )
        end

        def to_param
          'asana'
        end

        def supported_events
          %w[push]
        end

        def restrict_to_branch_help
          s_('AsanaService|Comma-separated list of branches to be automatically inspected. ' \
            'Leave blank to include all branches.')
        end

        def restrict_to_branch_description
          s_('Comma-separated list of branches to be automatically inspected. ' \
            'Leave blank to include all branches.')
        end

        def api_key_help
          s_('AsanaService|User personal access token. User must have access to the task. ' \
            'All comments are attributed to this user.')
        end

        def api_key_description
          s_('User API token. The user must have access to the task. ' \
            'All comments are attributed to this user.')
        end
      end

      included do
        validates :api_key, presence: true, if: :activated?

        field :api_key,
          type: :password,
          title: 'API key',
          help: -> { api_key_help },
          non_empty_password_title: -> { s_('ProjectService|Enter new API key') },
          non_empty_password_help: -> { s_('ProjectService|Leave blank to use your current API key.') },
          placeholder: '0/68a9e79b868c6789e79a124c30b0', # Example personal access token from Asana docs
          description: -> { api_key_description },
          required: true

        field :restrict_to_branch,
          title: -> { s_('Integrations|Restrict to branch (optional)') },
          help: -> { restrict_to_branch_help },
          description: -> { restrict_to_branch_description }
      end

      def execute(data)
        return unless supported_events.include?(data[:object_kind])

        branch = Gitlab::Git.ref_name(data[:ref])

        return unless branch_allowed?(branch)

        user = data[:user_name]
        project_name = project.full_name

        data[:commits].each do |commit|
          push_msg = format(
            s_("AsanaService|%{user} pushed to branch %{branch} of %{project_name} ( %{commit_url} ):"),
            user: user,
            branch: branch,
            project_name: project_name,
            commit_url: commit[:url]
          )

          check_commit(commit[:message], push_msg)
        end
      end

      def check_commit(message, push_msg)
        # matches either:
        # - #1234
        # - https://app.asana.com/0/{project_gid}/{task_gid}
        # optionally preceded with:
        # - fix/ed/es/ing
        # - close/s/d
        # - closing
        issue_finder = %r{(?:https://app\.asana\.com/\d+/\w+/(\w+)|#(\w+))}i
        proceded_keyword_finder = %r{(fix\w*|clos[ei]\w*)\s*\z}i

        message.split(issue_finder).each_slice(2) do |prepended_text, task_id|
          next unless task_id

          begin
            story_on_task_url = format(STORY_URL_TEMPLATE, task_gid: task_id)
            Gitlab::HTTP.post(
              story_on_task_url,
              headers: { "Authorization" => "Bearer #{api_key}" },
              body: { text: "#{push_msg} #{message}" }
            )

            if prepended_text.match?(proceded_keyword_finder)
              task_url = format(TASK_URL_TEMPLATE, task_gid: task_id)
              Gitlab::HTTP.put(task_url, headers: { "Authorization" => "Bearer #{api_key}" }, body: { completed: true })
            end
          rescue StandardError => e
            log_error(e.message)
            next
          end
        end
      end

      def test(_)
        result = Gitlab::HTTP.get(PERSONAL_ACCESS_TOKEN_TEST_URL, headers: { "Authorization" => "Bearer #{api_key}" })

        if result.success?
          { success: true }
        else
          { success: false, result: result.message }
        end
      end

      private

      def branch_allowed?(branch_name)
        return true if restrict_to_branch.blank?

        restrict_to_branch.to_s.gsub(/\s+/, '').split(',').include?(branch_name)
      end
    end
  end
end
