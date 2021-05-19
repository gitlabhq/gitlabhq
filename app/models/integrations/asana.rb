# frozen_string_literal: true

require 'asana'

module Integrations
  class Asana < Integration
    include ActionView::Helpers::UrlHelper

    prop_accessor :api_key, :restrict_to_branch
    validates :api_key, presence: true, if: :activated?

    def title
      'Asana'
    end

    def description
      s_('AsanaService|Add commit messages as comments to Asana tasks.')
    end

    def help
      docs_link = link_to _('Learn more.'), Rails.application.routes.url_helpers.help_page_url('user/project/integrations/asana'), target: '_blank', rel: 'noopener noreferrer'
      s_('Add commit messages as comments to Asana tasks. %{docs_link}').html_safe % { docs_link: docs_link.html_safe }
    end

    def self.to_param
      'asana'
    end

    def fields
      [
        {
          type: 'text',
          name: 'api_key',
          title: 'API key',
          help: s_('AsanaService|User Personal Access Token. User must have access to the task. All comments are attributed to this user.'),
          # Example Personal Access Token from Asana docs
          placeholder: '0/68a9e79b868c6789e79a124c30b0',
          required: true
        },
        {
          type: 'text',
          name: 'restrict_to_branch',
          title: 'Restrict to branch (optional)',
          help: s_('AsanaService|Comma-separated list of branches to be automatically inspected. Leave blank to include all branches.')
        }
      ]
    end

    def self.supported_events
      %w(push)
    end

    def client
      @_client ||= begin
        ::Asana::Client.new do |c|
          c.authentication :access_token, api_key
        end
      end
    end

    def execute(data)
      return unless supported_events.include?(data[:object_kind])

      # check the branch restriction is poplulated and branch is not included
      branch = Gitlab::Git.ref_name(data[:ref])
      branch_restriction = restrict_to_branch.to_s
      if branch_restriction.present? && branch_restriction.index(branch).nil?
        return
      end

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
  end
end
