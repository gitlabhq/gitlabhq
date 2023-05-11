# frozen_string_literal: true

# Accessible as Project#external_issue_tracker
module Integrations
  class Jira < BaseIssueTracker
    include Gitlab::Routing
    include ApplicationHelper
    include ActionView::Helpers::AssetUrlHelper
    include Gitlab::Utils::StrongMemoize

    PROJECTS_PER_PAGE = 50
    JIRA_CLOUD_HOST = '.atlassian.net'

    ATLASSIAN_REFERRER_GITLAB_COM = { atlOrigin: 'eyJpIjoiY2QyZTJiZDRkNGZhNGZlMWI3NzRkNTBmZmVlNzNiZTkiLCJwIjoianN3LWdpdGxhYi1pbnQifQ' }.freeze
    ATLASSIAN_REFERRER_SELF_MANAGED = { atlOrigin: 'eyJpIjoiYjM0MTA4MzUyYTYxNDVkY2IwMzVjOGQ3ZWQ3NzMwM2QiLCJwIjoianN3LWdpdGxhYlNNLWludCJ9' }.freeze

    SECTION_TYPE_JIRA_TRIGGER = 'jira_trigger'
    SECTION_TYPE_JIRA_ISSUES = 'jira_issues'

    AUTH_TYPE_BASIC = 0
    AUTH_TYPE_PAT = 1

    SNOWPLOW_EVENT_CATEGORY = self.name

    validates :url, public_url: true, presence: true, if: :activated?
    validates :api_url, public_url: true, allow_blank: true
    validates :username, presence: true, if: ->(object) { object.activated? && !object.personal_access_token_authorization? }
    validates :password, presence: true, if: :activated?
    validates :jira_auth_type, presence: true, inclusion: { in: [AUTH_TYPE_BASIC, AUTH_TYPE_PAT] }, if: :activated?
    validates :jira_issue_prefix, untrusted_regexp: true, length: { maximum: 255 }, if: :activated?
    validates :jira_issue_regex,  untrusted_regexp: true, length: { maximum: 255 }, if: :activated?
    validate :validate_jira_cloud_auth_type_is_basic, if: :activated?

    validates :jira_issue_transition_id,
              format: {
                with: Gitlab::Regex.jira_transition_id_regex,
                message: ->(*_) { s_("JiraService|IDs must be a list of numbers that can be split with , or ;") }
              },
              allow_blank: true

    # Jira Cloud version is deprecating authentication via username and password.
    # We should use username/password for Jira Server and email/api_token for Jira Cloud,
    # for more information check: https://gitlab.com/gitlab-org/gitlab-foss/issues/49936.

    after_commit :update_deployment_type, on: [:create, :update], if: :update_deployment_type?

    enum comment_detail: {
      standard: 1,
      all_details: 2
    }

    self.field_storage = :data_fields

    field :url,
          section: SECTION_TYPE_CONNECTION,
          required: true,
          title: -> { s_('JiraService|Web URL') },
          help: -> { s_('JiraService|Base URL of the Jira instance') },
          placeholder: 'https://jira.example.com',
          exposes_secrets: true

    field :api_url,
          section: SECTION_TYPE_CONNECTION,
          title: -> { s_('JiraService|Jira API URL') },
          help: -> { s_('JiraService|If different from the Web URL') },
          exposes_secrets: true

    field :jira_auth_type,
          type: 'select',
          required: true,
          section: SECTION_TYPE_CONNECTION,
          title: -> { s_('JiraService|Authentication type') },
          choices: -> {
            [
              [s_('JiraService|Basic'), AUTH_TYPE_BASIC],
              [s_('JiraService|Jira personal access token (Jira Data Center and Jira Server only)'), AUTH_TYPE_PAT]
            ]
          }

    field :username,
          section: SECTION_TYPE_CONNECTION,
          required: false,
          title: -> { s_('JiraService|Email or username') },
          help: -> { s_('JiraService|Only required for Basic authentication. Email for Jira Cloud or username for Jira Data Center and Jira Server') }

    field :password,
          section: SECTION_TYPE_CONNECTION,
          required: true,
          title: -> { s_('JiraService|Password or API token') },
          non_empty_password_title: -> { s_('JiraService|New API token, password, or Jira personal access token') },
          non_empty_password_help: -> { s_('JiraService|Leave blank to use your current configuration') },
          help: -> { s_('JiraService|API token for Jira Cloud or password for Jira Data Center and Jira Server') },
          is_secret: true

    field :jira_issue_regex,
           section: SECTION_TYPE_CONFIGURATION,
           required: false,
           title: -> { s_('JiraService|Jira issue regex') },
           help: -> { s_('JiraService|Use regular expression to match Jira issue keys.') }

    field :jira_issue_prefix,
          section: SECTION_TYPE_CONFIGURATION,
          required: false,
          title: -> { s_('JiraService|Jira issue prefix') },
          help: -> { s_('JiraService|Use a prefix to match Jira issue keys.') }

    field :jira_issue_transition_id, api_only: true

    # TODO: we can probably just delegate as part of
    # https://gitlab.com/gitlab-org/gitlab/issues/29404
    # These fields are API only, so no field definition is required.
    data_field :jira_issue_transition_automatic
    data_field :project_key
    data_field :issues_enabled
    data_field :vulnerabilities_enabled
    data_field :vulnerabilities_issuetype

    # When these are false GitLab does not create cross reference
    # comments on Jira except when an issue gets transitioned.
    def self.supported_events
      %w(commit merge_request)
    end

    # {PROJECT-KEY}-{NUMBER} Examples: JIRA-1, PROJECT-1
    def reference_pattern(only_long: true)
      @reference_pattern ||= jira_issue_match_regex
    end

    def self.valid_jira_cloud_url?(url)
      return false unless url.present?

      uri = URI.parse(url)
      uri.is_a?(URI::HTTPS) && !!uri.hostname&.end_with?(JIRA_CLOUD_HOST)
    rescue URI::InvalidURIError
      false
    end

    def data_fields
      jira_tracker_data || self.build_jira_tracker_data
    end

    def set_default_data
      return unless issues_tracker.present?

      return if url

      data_fields.url ||= issues_tracker['url']
      data_fields.api_url ||= issues_tracker['api_url']
    end

    def options
      url = URI.parse(client_url)

      options = {
        site: URI.join(url, '/').to_s.chomp('/'), # Find the root URL
        context_path: (url.path.presence || '/').delete_suffix('/'),
        auth_type: :basic,
        use_ssl: url.scheme == 'https'
      }

      if personal_access_token_authorization?
        options[:default_headers] = { 'Authorization' => "Bearer #{password}" }
      else
        options[:username] = username&.strip
        options[:password] = password
        options[:use_cookies] = true
        options[:additional_cookies] = ['OBBasicAuth=fromDialog']
      end

      options
    end

    def client
      @client ||= JIRA::Client.new(options).tap do |client|
        # Replaces JIRA default http client with our implementation
        client.request_client = Gitlab::Jira::HttpClient.new(client.options)
      end
    end

    def help
      jira_doc_link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: help_page_path('integration/jira/index') }
      s_("JiraService|You must configure Jira before enabling this integration. %{jira_doc_link_start}Learn more.%{link_end}") % { jira_doc_link_start: jira_doc_link_start, link_end: '</a>'.html_safe }
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

    def sections
      sections = [
        {
          type: SECTION_TYPE_CONNECTION,
          title: s_('Integrations|Connection details'),
          description: help
        },
        {
          type: SECTION_TYPE_JIRA_TRIGGER,
          title: _('Trigger'),
          description: s_('JiraService|When a Jira issue is mentioned in a commit or merge request, a remote link and comment (if enabled) will be created.')
        },
        {
          type: SECTION_TYPE_CONFIGURATION,
          title: _('Jira issue matching'),
          description: s_('Configure custom rules for Jira issue key matching')
        }
      ]

      # Jira issues is currently only configurable on the project level.
      if project_level?
        sections.push({
          type: SECTION_TYPE_JIRA_ISSUES,
          title: _('Issues'),
          description: jira_issues_section_description,
          plan: 'premium'
        })
      end

      sections
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

    alias_method :project_url, :web_url

    def issues_url
      web_url('browse/:id')
    end

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

    def find_issue(issue_key, rendered_fields: false, transitions: false, restrict_project_key: false)
      return if restrict_project_key && parse_project_from_issue_key(issue_key) != project_key

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
    def create_cross_reference_note(external_issue, mentioned_in, author)
      unless can_cross_reference?(mentioned_in)
        return s_("JiraService|Events for %{noteable_model_name} are disabled.") % { noteable_model_name: mentioned_in.model_name.plural.humanize(capitalize: false) }
      end

      jira_issue = find_issue(external_issue.id)

      return unless jira_issue.present?

      mentioned_in_id = mentioned_in.respond_to?(:iid) ? mentioned_in.iid : mentioned_in.id
      mentioned_in_type = mentionable_name(mentioned_in)
      entity_url = build_entity_url(mentioned_in_type, mentioned_in_id)
      entity_meta = build_entity_meta(mentioned_in)

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
          name: mentioned_in_type.humanize.downcase,
          url: entity_url,
          title: mentioned_in.title,
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

    def personal_access_token_authorization?
      jira_auth_type == AUTH_TYPE_PAT
    end

    private

    def jira_issue_match_regex
      match_regex = (jira_issue_regex.presence || Gitlab::Regex.jira_issue_key_regex)

      /\b#{jira_issue_prefix}(?<issue>#{match_regex})/
    end

    def parse_project_from_issue_key(issue_key)
      issue_key.gsub(Gitlab::Regex.jira_issue_key_project_key_extraction_regex, '')
    end

    def branch_name(commit)
      commit.first_ref_by_oid(project.repository)
    end

    def server_info
      strong_memoize(:server_info) do
        client_url.present? ? jira_request { client.ServerInfo.all.attrs } : nil
      end
    end

    def can_cross_reference?(mentioned_in)
      case mentioned_in
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
    rescue StandardError => e
      log_exception(e, message: 'Issue transition failed', client_url: client_url)
      false
    end

    def transition_issue_to_done(issue)
      transitions = begin
        issue.transitions
      rescue StandardError
        []
      end

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

      optional_arguments = {
        project: project,
        namespace: group || project&.namespace
      }.compact

      Gitlab::Tracking.event(
        SNOWPLOW_EVENT_CATEGORY,
        Integration::SNOWPLOW_EVENT_ACTION,
        label: Integration::SNOWPLOW_EVENT_LABEL,
        property: key,
        user: user,
        context: [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: key).to_context],
        **optional_arguments
      )
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

    def build_entity_url(entity_type, entity_id)
      polymorphic_url(
        [
          self.project,
          entity_type.to_sym
        ],
        id: entity_id,
        host: Settings.gitlab.base_url
      )
    end

    def build_entity_meta(entity)
      case entity
      when Commit
        {
          id: entity.short_id,
          description: entity.safe_message,
          branch: branch_name(entity)
        }
      when MergeRequest
        {
          id: entity.to_reference,
          branch: entity.source_branch
        }
      else
        {}
      end
    end

    def mentionable_name(mentionable)
      name = mentionable.model_name.singular

      # ProjectSnippet inherits from Snippet class so it causes
      # routing error building the URL.
      name == "project_snippet" ? "snippet" : name
    end

    # Handle errors when doing Jira API calls
    def jira_request
      yield
    rescue StandardError => e
      @error = e
      log_exception(e, message: 'Error sending message', client_url: client_url)
      nil
    end

    def client_url
      api_url.presence || url
    end

    def update_deployment_type?
      api_url_changed? || url_changed? || username_changed? || password_changed?
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
      server_info['deploymentType'] == 'Cloud' || self.class.valid_jira_cloud_url?(client_url)
    end

    def set_deployment_type_from_url
      # This shouldn't happen but of course it will happen when an integration is removed.
      # Instead of deleting the integration we set all fields to null
      # and mark it as inactive
      return data_fields.deployment_unknown! unless client_url

      # If API-based detection methods fail here then
      # we can only assume it's either Cloud or Server
      # based on the URL being *.atlassian.net
      if self.class.valid_jira_cloud_url?(client_url)
        data_fields.deployment_cloud!
      else
        data_fields.deployment_server!
      end
    end

    def jira_issues_section_description
      jira_issues_link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: help_page_path('integration/jira/issues') }
      description = s_('JiraService|Work on Jira issues without leaving GitLab. Add a Jira menu to access a read-only list of your Jira issues. %{jira_issues_link_start}Learn more.%{link_end}') % { jira_issues_link_start: jira_issues_link_start, link_end: '</a>'.html_safe }

      if project&.issues_enabled?
        gitlab_issues_link_start = '<a href="%{url}">'.html_safe % { url: edit_project_path(project, anchor: 'js-shared-permissions') }
        description += '<br><br>'.html_safe
        description += s_("JiraService|Displaying Jira issues while leaving GitLab issues also enabled might be confusing. Consider %{gitlab_issues_link_start}disabling GitLab issues%{link_end} if they won't otherwise be used.") % { gitlab_issues_link_start: gitlab_issues_link_start, link_end: '</a>'.html_safe }
      end

      description
    end

    def validate_jira_cloud_auth_type_is_basic
      return unless self.class.valid_jira_cloud_url?(client_url) && jira_auth_type != AUTH_TYPE_BASIC

      errors.add(:base,
        format(
          s_('JiraService|For Jira Cloud, the authentication type must be %{basic}'),
          basic: s_('JiraService|Basic')
        )
      )
    end
  end
end

Integrations::Jira.prepend_mod_with('Integrations::Jira')
