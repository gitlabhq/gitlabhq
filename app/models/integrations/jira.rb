# frozen_string_literal: true

# Accessible as Project#external_issue_tracker
module Integrations
  class Jira < BaseIssueTracker
    extend ::Gitlab::Utils::Override
    include Gitlab::Routing
    include ApplicationHelper
    include ActionView::Helpers::AssetUrlHelper
    include Gitlab::Utils::StrongMemoize

    PROJECTS_PER_PAGE = 50
    JIRA_CLOUD_HOST = '.atlassian.net'

    ATLASSIAN_REFERRER_GITLAB_COM = { atlOrigin: 'eyJpIjoiY2QyZTJiZDRkNGZhNGZlMWI3NzRkNTBmZmVlNzNiZTkiLCJwIjoianN3LWdpdGxhYi1pbnQifQ' }.freeze
    ATLASSIAN_REFERRER_SELF_MANAGED = { atlOrigin: 'eyJpIjoiYjM0MTA4MzUyYTYxNDVkY2IwMzVjOGQ3ZWQ3NzMwM2QiLCJwIjoianN3LWdpdGxhYlNNLWludCJ9' }.freeze

    validates :url, public_url: true, presence: true, if: :activated?
    validates :api_url, public_url: true, allow_blank: true
    validates :username, presence: true, if: :activated?
    validates :password, presence: true, if: :activated?

    validates :jira_issue_transition_id,
              format: { with: Gitlab::Regex.jira_transition_id_regex, message: s_("JiraService|IDs must be a list of numbers that can be split with , or ;") },
              allow_blank: true

    # Jira Cloud version is deprecating authentication via username and password.
    # We should use username/password for Jira Server and email/api_token for Jira Cloud,
    # for more information check: https://gitlab.com/gitlab-org/gitlab-foss/issues/49936.

    # TODO: we can probably just delegate as part of
    # https://gitlab.com/gitlab-org/gitlab/issues/29404
    data_field :username, :password, :url, :api_url, :jira_issue_transition_automatic, :jira_issue_transition_id, :project_key, :issues_enabled,
      :vulnerabilities_enabled, :vulnerabilities_issuetype

    before_validation :reset_password
    after_commit :update_deployment_type, on: [:create, :update], if: :update_deployment_type?

    enum comment_detail: {
      standard: 1,
      all_details: 2
    }

    # When these are false GitLab does not create cross reference
    # comments on Jira except when an issue gets transitioned.
    def self.supported_events
      %w(commit merge_request)
    end

    def self.supported_event_actions
      %w(comment)
    end

    # {PROJECT-KEY}-{NUMBER} Examples: JIRA-1, PROJECT-1
    def self.reference_pattern(only_long: true)
      @reference_pattern ||= /(?<issue>\b#{Gitlab::Regex.jira_issue_key_regex})/
    end

    def initialize_properties
      {}
    end

    def data_fields
      jira_tracker_data || self.build_jira_tracker_data
    end

    def reset_password
      return unless reset_password?

      data_fields.password = nil
      properties.delete('password') if properties
    end

    def set_default_data
      return unless issues_tracker.present?

      return if url

      data_fields.url ||= issues_tracker['url']
      data_fields.api_url ||= issues_tracker['api_url']
    end

    def options
      url = URI.parse(client_url)

      {
        username: username&.strip,
        password: password,
        site: URI.join(url, '/').to_s.delete_suffix('/'), # Intended to find the root
        context_path: (url.path.presence || '/').delete_suffix('/'),
        auth_type: :basic,
        read_timeout: 120,
        use_cookies: true,
        additional_cookies: ['OBBasicAuth=fromDialog'],
        use_ssl: url.scheme == 'https'
      }
    end

    def client
      @client ||= begin
        JIRA::Client.new(options).tap do |client|
          # Replaces JIRA default http client with our implementation
          client.request_client = Gitlab::Jira::HttpClient.new(client.options)
        end
      end
    end

    def help
      jira_doc_link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: help_page_url('integration/jira/index.html') }
      s_("JiraService|You need to configure Jira before enabling this integration. For more details, read the %{jira_doc_link_start}Jira integration documentation%{link_end}.") % { jira_doc_link_start: jira_doc_link_start, link_end: '</a>'.html_safe }
    end

    def title
      'Jira'
    end

    def description
      s_("JiraService|Use Jira as this project's issue tracker.")
    end

    def self.to_param
      'jira'
    end

    def fields
      [
        {
          type: 'text',
          name: 'url',
          title: s_('JiraService|Web URL'),
          placeholder: 'https://jira.example.com',
          help: s_('JiraService|Base URL of the Jira instance.'),
          required: true
        },
        {
          type: 'text',
          name: 'api_url',
          title: s_('JiraService|Jira API URL'),
          help: s_('JiraService|If different from Web URL.')
        },
        {
          type: 'text',
          name: 'username',
          title: s_('JiraService|Username or Email'),
          help: s_('JiraService|Use a username for server version and an email for cloud version.'),
          required: true
        },
        {
          type: 'password',
          name: 'password',
          title: s_('JiraService|Password or API token'),
          non_empty_password_title: s_('JiraService|Enter new password or API token'),
          non_empty_password_help: s_('JiraService|Leave blank to use your current password or API token.'),
          help: s_('JiraService|Use a password for server version and an API token for cloud version.'),
          required: true
        }
      ]
    end

    def web_url(path = nil, **params)
      return '' unless url.present?

      if Gitlab.com?
        params.merge!(ATLASSIAN_REFERRER_GITLAB_COM) unless Gitlab.staging?
      else
        params.merge!(ATLASSIAN_REFERRER_SELF_MANAGED) unless Gitlab.dev_or_test_env?
      end

      url = Addressable::URI.parse(self.url)
      url.path = url.path.delete_suffix('/')
      url.path << "/#{path.delete_prefix('/').delete_suffix('/')}" if path.present?
      url.query_values = (url.query_values || {}).merge(params)
      url.query_values = nil if url.query_values.empty?

      url.to_s
    end

    override :project_url
    def project_url
      web_url
    end

    override :issues_url
    def issues_url
      web_url('browse/:id')
    end

    override :new_issue_url
    def new_issue_url
      web_url('secure/CreateIssue!default.jspa')
    end

    alias_method :original_url, :url
    def url
      original_url&.delete_suffix('/')
    end

    alias_method :original_api_url, :api_url
    def api_url
      original_api_url&.delete_suffix('/')
    end

    def execute(push)
      # This method is a no-op, because currently Integrations::Jira does not
      # support any events.
    end

    def find_issue(issue_key, rendered_fields: false, transitions: false)
      expands = []
      expands << 'renderedFields' if rendered_fields
      expands << 'transitions' if transitions
      options = { expand: expands.join(',') } if expands.any?

      jira_request { client.Issue.find(issue_key, options || {}) }
    end

    def close_issue(entity, external_issue, current_user)
      issue = find_issue(external_issue.iid, transitions: jira_issue_transition_automatic)

      return if issue.nil? || has_resolution?(issue) || !issue_transition_enabled?

      commit_id = case entity
                  when Commit then entity.id
                  when MergeRequest then entity.diff_head_sha
                  end

      commit_url = build_entity_url(:commit, commit_id)

      # Depending on the Jira project's workflow, a comment during transition
      # may or may not be allowed. Refresh the issue after transition and check
      # if it is closed, so we don't have one comment for every commit.
      issue = find_issue(issue.key) if transition_issue(issue)
      add_issue_solved_comment(issue, commit_id, commit_url) if has_resolution?(issue)
      log_usage(:close_issue, current_user)
    end

    override :create_cross_reference_note
    def create_cross_reference_note(mentioned, noteable, author)
      unless can_cross_reference?(noteable)
        return s_("JiraService|Events for %{noteable_model_name} are disabled.") % { noteable_model_name: noteable.model_name.plural.humanize(capitalize: false) }
      end

      jira_issue = find_issue(mentioned.id)

      return unless jira_issue.present?

      noteable_id   = noteable.respond_to?(:iid) ? noteable.iid : noteable.id
      noteable_type = noteable_name(noteable)
      entity_url    = build_entity_url(noteable_type, noteable_id)
      entity_meta   = build_entity_meta(noteable)

      data = {
        user: {
          name: author.name,
          url: resource_url(user_path(author))
        },
        project: {
          name: project.full_path,
          url: resource_url(project_path(project))
        },
        entity: {
          id: entity_meta[:id],
          name: noteable_type.humanize.downcase,
          url: entity_url,
          title: noteable.title,
          description: entity_meta[:description],
          branch: entity_meta[:branch]
        }
      }

      add_comment(data, jira_issue).tap { log_usage(:cross_reference, author) }
    end

    def valid_connection?
      test(nil)[:success]
    end

    def configured?
      active? && valid_connection?
    end

    def test(_)
      result = server_info
      success = result.present?
      result = @error&.message unless success

      { success: success, result: result }
    end

    override :support_close_issue?
    def support_close_issue?
      true
    end

    override :support_cross_reference?
    def support_cross_reference?
      true
    end

    def issue_transition_enabled?
      jira_issue_transition_automatic || jira_issue_transition_id.present?
    end

    private

    def server_info
      strong_memoize(:server_info) do
        client_url.present? ? jira_request { client.ServerInfo.all.attrs } : nil
      end
    end

    def can_cross_reference?(noteable)
      case noteable
      when Commit then commit_events
      when MergeRequest then merge_requests_events
      else true
      end
    end

    # jira_issue_transition_id can have multiple values split by , or ;
    # the issue is transitioned at the order given by the user
    # if any transition fails it will log the error message and stop the transition sequence
    def transition_issue(issue)
      return transition_issue_to_done(issue) if jira_issue_transition_automatic

      jira_issue_transition_id.scan(Gitlab::Regex.jira_transition_id_regex).all? do |transition_id|
        transition_issue_to_id(issue, transition_id)
      end
    end

    def transition_issue_to_id(issue, transition_id)
      issue.transitions.build.save!(
        transition: { id: transition_id }
      )

      true
    rescue StandardError => error
      log_error(
        "Issue transition failed",
          error: {
            exception_class: error.class.name,
            exception_message: error.message,
            exception_backtrace: Gitlab::BacktraceCleaner.clean_backtrace(error.backtrace)
          },
          client_url: client_url
      )

      false
    end

    def transition_issue_to_done(issue)
      transitions = issue.transitions rescue []

      transition = transitions.find do |transition|
        status = transition&.to&.statusCategory
        status && status['key'] == 'done'
      end

      return false unless transition

      transition_issue_to_id(issue, transition.id)
    end

    def log_usage(action, user)
      key = "i_ecosystem_jira_service_#{action}"

      Gitlab::UsageDataCounters::HLLRedisCounter.track_event(key, values: user.id)
    end

    def add_issue_solved_comment(issue, commit_id, commit_url)
      link_title   = "Solved by commit #{commit_id}."
      comment      = "Issue solved with [#{commit_id}|#{commit_url}]."
      link_props   = build_remote_link_props(url: commit_url, title: link_title, resolved: true)
      send_message(issue, comment, link_props)
    end

    def add_comment(data, issue)
      entity_name  = data[:entity][:name]
      entity_url   = data[:entity][:url]
      entity_title = data[:entity][:title]

      message      = comment_message(data)
      link_title   = "#{entity_name.capitalize} - #{entity_title}"
      link_props   = build_remote_link_props(url: entity_url, title: link_title)

      unless comment_exists?(issue, message)
        send_message(issue, message, link_props)
      end
    end

    def comment_message(data)
      user_link = build_jira_link(data[:user][:name], data[:user][:url])

      entity = data[:entity]
      entity_ref = all_details? ? "#{entity[:name]} #{entity[:id]}" : "a #{entity[:name]}"
      entity_link = build_jira_link(entity_ref, entity[:url])

      project_link = build_jira_link(project.full_name, Gitlab::Routing.url_helpers.project_url(project))
      branch =
        if entity[:branch].present?
          s_('JiraService| on branch %{branch_link}') % {
            branch_link: build_jira_link(entity[:branch], project_tree_url(project, entity[:branch]))
          }
        end

      entity_message = entity[:description].presence if all_details?
      entity_message ||= entity[:title].chomp

      s_('JiraService|%{user_link} mentioned this issue in %{entity_link} of %{project_link}%{branch}:{quote}%{entity_message}{quote}') % {
        user_link: user_link,
        entity_link: entity_link,
        project_link: project_link,
        branch: branch,
        entity_message: entity_message
      }
    end

    def build_jira_link(title, url)
      "[#{title}|#{url}]"
    end

    def has_resolution?(issue)
      issue.respond_to?(:resolution) && issue.resolution.present?
    end

    def comment_exists?(issue, message)
      comments = jira_request { issue.comments }

      comments.present? && comments.any? { |comment| comment.body.include?(message) }
    end

    def send_message(issue, message, remote_link_props)
      return unless client_url.present?

      jira_request do
        remote_link = find_remote_link(issue, remote_link_props[:object][:url])

        create_issue_comment(issue, message) unless remote_link
        remote_link ||= issue.remotelink.build
        remote_link.save!(remote_link_props)

        log_info("Successfully posted", client_url: client_url)
        "SUCCESS: Successfully posted to #{client_url}."
      end
    end

    def create_issue_comment(issue, message)
      return unless comment_on_event_enabled

      issue.comments.build.save!(body: message)
    end

    def find_remote_link(issue, url)
      links = jira_request { issue.remotelink.all }
      return unless links

      links.find { |link| link.object["url"] == url }
    end

    def build_remote_link_props(url:, title:, resolved: false)
      status = {
        resolved: resolved
      }

      {
        GlobalID: 'GitLab',
        relationship: 'mentioned on',
        object: {
          url: url,
          title: title,
          status: status,
          icon: {
            title: 'GitLab', url16x16: asset_url(Gitlab::Favicon.main, host: gitlab_config.base_url)
          }
        }
      }
    end

    def resource_url(resource)
      "#{Settings.gitlab.base_url.chomp("/")}#{resource}"
    end

    def build_entity_url(noteable_type, entity_id)
      polymorphic_url(
        [
          self.project,
          noteable_type.to_sym
        ],
        id:   entity_id,
        host: Settings.gitlab.base_url
      )
    end

    def build_entity_meta(noteable)
      if noteable.is_a?(Commit)
        {
          id: noteable.short_id,
          description: noteable.safe_message,
          branch: noteable.ref_names(project.repository).first
        }
      elsif noteable.is_a?(MergeRequest)
        {
          id: noteable.to_reference,
          branch: noteable.source_branch
        }
      else
        {}
      end
    end

    def noteable_name(noteable)
      name = noteable.model_name.singular

      # ProjectSnippet inherits from Snippet class so it causes
      # routing error building the URL.
      name == "project_snippet" ? "snippet" : name
    end

    # Handle errors when doing Jira API calls
    def jira_request
      yield
    rescue StandardError => error
      @error = error
      log_error("Error sending message", client_url: client_url, error: @error.message)
      nil
    end

    def client_url
      api_url.presence || url
    end

    def reset_password?
      # don't reset the password if a new one is provided
      return false if password_touched?
      return true if api_url_changed?
      return false if api_url.present?

      url_changed?
    end

    def update_deployment_type?
      (api_url_changed? || url_changed? || username_changed? || password_changed?) &&
        testable?
    end

    def update_deployment_type
      clear_memoization(:server_info) # ensure we run the request when we try to update deployment type
      results = server_info

      unless results.present?
        Gitlab::AppLogger.warn(message: "Jira API returned no ServerInfo, setting deployment_type from URL", server_info: results, url: client_url)

        return set_deployment_type_from_url
      end

      if jira_cloud?
        data_fields.deployment_cloud!
      else
        data_fields.deployment_server!
      end
    end

    def jira_cloud?
      server_info['deploymentType'] == 'Cloud' || URI(client_url).hostname.end_with?(JIRA_CLOUD_HOST)
    end

    def set_deployment_type_from_url
      # This shouldn't happen but of course it will happen when an integration is removed.
      # Instead of deleting the integration we set all fields to null
      # and mark it as inactive
      return data_fields.deployment_unknown! unless client_url

      # If API-based detection methods fail here then
      # we can only assume it's either Cloud or Server
      # based on the URL being *.atlassian.net

      if URI(client_url).hostname.end_with?(JIRA_CLOUD_HOST)
        data_fields.deployment_cloud!
      else
        data_fields.deployment_server!
      end
    end
  end
end

Integrations::Jira.prepend_mod_with('Integrations::Jira')
