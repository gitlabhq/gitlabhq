# frozen_string_literal: true

require 'asana'

module Integrations
  class Asana < Integration
    validates :api_key, presence: true, if: :activated?

    field :api_key,
      type: 'password',
      title: 'API key',
      help: -> { s_('AsanaService|User Personal Access Token. User must have access to the task. All comments are attributed to this user.') },
      non_empty_password_title: -> { s_('ProjectService|Enter new API key') },
      non_empty_password_help: -> { s_('ProjectService|Leave blank to use your current API key.') },
      # Example Personal Access Token from Asana docs
      placeholder: '0/68a9e79b868c6789e79a124c30b0',
      required: true

    field :restrict_to_branch,
      title: -> { s_('Integrations|Restrict to branch (optional)') },
      help: -> { s_('AsanaService|Comma-separated list of branches to be automatically inspected. Leave blank to include all branches.') }

    def title
      'Asana'
    end

    def description
      s_('AsanaService|Add commit messages as comments to Asana tasks.')
    end

    def help
      docs_link = ActionController::Base.helpers.link_to _('Learn more.'), Rails.application.routes.url_helpers.help_page_url('user/project/integrations/asana'), target: '_blank', rel: 'noopener noreferrer'
      s_('Add commit messages as comments to Asana tasks. %{docs_link}').html_safe % { docs_link: docs_link.html_safe }
    end

    def self.to_param
      'asana'
    end

    def self.supported_events
      %w(push)
    end

    def client
      @_client ||= ::Asana::Client.new do |c|
        c.authentication :access_token, api_key
      end
    end

    def execute(data)
      return unless supported_events.include?(data[:object_kind])

      branch = Gitlab::Git.ref_name(data[:ref])

      return unless branch_allowed?(branch)

      user = data[:user_name]
      project_name = project.full_name

      data[:commits].each do |commit|
        push_msg = s_("AsanaService|%{user} pushed to branch %{branch} of %{project_name} ( %{commit_url} ):") % { user: user, branch: branch, project_name: project_name, commit_url: commit[:url] }
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
      issue_finder = %r{(fix\w*|clos[ei]\w*+)?\W*(?:https://app\.asana\.com/\d+/\w+/(\w+)|#(\w+))}i

      message.scan(issue_finder).each do |tuple|
        # tuple will be
        # [ 'fix', 'id_from_url', 'id_from_pound' ]
        taskid = tuple[2] || tuple[1]

        begin
          task = ::Asana::Resources::Task.find_by_id(client, taskid)
          task.add_comment(text: "#{push_msg} #{message}")

          if tuple[0]
            task.update(completed: true)
          end
        rescue StandardError => e
          log_error(e.message)
          next
        end
      end
    end

    private

    def branch_allowed?(branch_name)
      return true if restrict_to_branch.blank?

      restrict_to_branch.to_s.gsub(/\s+/, '').split(',').include?(branch_name)
    end
  end
end
