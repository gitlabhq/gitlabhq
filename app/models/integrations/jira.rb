# frozen_string_literal: true

# Accessible as Project#external_issue_tracker
module Integrations
  class Jira < Integration
    include Base::IssueTracker
    include Gitlab::Routing
    include ApplicationHelper
    include SafeFormatHelper
    include ActionView::Helpers::AssetUrlHelper
    include Gitlab::Utils::StrongMemoize
    include HasAvatar

    PROJECTS_PER_PAGE = 50
    JIRA_CLOUD_HOST = '.atlassian.net'

    ATLASSIAN_REFERRER_GITLAB_COM = {
      atlOrigin: 'eyJpIjoiY2QyZTJiZDRkNGZhNGZlMWI3NzRkNTBmZmVlNzNiZTkiLCJwIjoianN3LWdpdGxhYi1pbnQifQ'
    }.freeze
    ATLASSIAN_REFERRER_SELF_MANAGED = {
      atlOrigin: 'eyJpIjoiYjM0MTA4MzUyYTYxNDVkY2IwMzVjOGQ3ZWQ3NzMwM2QiLCJwIjoianN3LWdpdGxhYlNNLWludCJ9'
    }.freeze

    API_ENDPOINTS = {
      find_issue: "/rest/api/2/issue/%s",
      server_info: "/rest/api/2/serverInfo",
      transition_issue: "/rest/api/2/issue/%s/transitions",
      issue_comments: "/rest/api/2/issue/%s/comment",
      link_remote_issue: "/rest/api/2/issue/%s/remotelink",
      client_info: "/rest/api/2/myself"
    }.freeze

    SECTION_TYPE_JIRA_TRIGGER = 'jira_trigger'
    SECTION_TYPE_JIRA_ISSUES = 'jira_issues'
    SECTION_TYPE_JIRA_ISSUE_CREATION = 'jira_issue_creation'

    AUTH_TYPE_BASIC = 0
    AUTH_TYPE_PAT = 1

    SNOWPLOW_EVENT_CATEGORY = name

    RE2_SYNTAX_DOC_URL = 'https://github.com/google/re2/wiki/Syntax'

    validates :url, public_url: true, presence: true, if: :activated?
    validates :api_url, public_url: true, allow_blank: true
    validates :username, presence: true, if: ->(object) {
                                               object.activated? && !object.personal_access_token_authorization?
                                             }
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

    before_save :format_project_keys, if: :project_keys_changed?
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
      description: -> {
        s_('JiraIntegration|The URL to the Jira project which is being linked to this GitLab project ' \
            '(for example, `https://jira.example.com`).')
      },
      placeholder: 'https://jira.example.com',
      exposes_secrets: true

    field :api_url,
      section: SECTION_TYPE_CONNECTION,
      title: -> { s_('JiraService|Jira API URL') },
      help: -> { s_('JiraService|If different from the Web URL') },
      exposes_secrets: true,
      description: -> do
        s_('JiraIntegration|The base URL to the Jira instance API. Web URL value is used if not set (for example, ' \
        '`https://jira-api.example.com`).')
      end

    field :jira_auth_type,
      type: :number,
      section: SECTION_TYPE_CONNECTION,
      title: -> { s_('JiraService|Authentication type') },
      choices: -> {
        [
          [s_('JiraService|Basic'), AUTH_TYPE_BASIC],
          [s_('JiraService|Jira personal access token (Jira Data Center and Jira Server only)'), AUTH_TYPE_PAT]
        ]
      },
      description: -> do
        s_('JiraIntegration|The authentication method to use with Jira. Use `0` for Basic Authentication, ' \
        'and `1` for Jira personal access token. Defaults to `0`.')
      end

    field :username,
      section: SECTION_TYPE_CONNECTION,
      required: false,
      title: -> { s_('JiraService|Email or username') },
      help: -> { s_('JiraService|Email for Jira Cloud or username for Jira Data Center and Jira Server') },
      description: -> {
        s_('JiraIntegration|The email or username to use with Jira. Use an email for Jira Cloud, and a username ' \
        'for Jira Data Center and Jira Server. Required when using Basic Authentication (`jira_auth_type` is `0`).')
      }

    field :password,
      section: SECTION_TYPE_CONNECTION,
      required: true,
      title: -> { s_('JiraService|API token or password') },
      non_empty_password_title: -> { s_('JiraService|New API token or password') },
      non_empty_password_help: -> { s_('JiraService|Leave blank to use your current configuration') },
      help: -> { s_('JiraService|API token for Jira Cloud or password for Jira Data Center and Jira Server') },
      description: -> {
        s_('JiraIntegration|The Jira API token, password, or personal access token to use with Jira. When using ' \
        'Basic Authentication (`jira_auth_type` is `0`), use an API token for Jira Cloud, and a password for ' \
        'Jira Data Center or Jira Server. For a Jira personal access token ' \
        '(`jira_auth_type` is `1`), use the personal access token.')
      },
      is_secret: true

    field :jira_issue_regex,
      section: SECTION_TYPE_CONFIGURATION,
      required: false,
      title: -> { s_('JiraService|Jira issue regex') },
      description: -> { s_('JiraIntegration|Regular expression to match Jira issue keys.') },
      help: -> do
        format(ERB::Util.html_escape(
          s_("JiraService|Use regular expression to match Jira issue keys. The regular expression must follow the " \
             "%{link_start}RE2 syntax%{link_end}. If empty, the default behavior is used.")),
          link_start: format('<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe,
            url: RE2_SYNTAX_DOC_URL),
          link_end: '</a>'.html_safe
        )
      end

    field :jira_issue_prefix,
      section: SECTION_TYPE_CONFIGURATION,
      required: false,
      title: -> { s_('JiraService|Jira issue prefix') },
      help: -> { s_('JiraService|Use a prefix to match Jira issue keys.') },
      description: -> { s_('JiraIntegration|Prefix to match Jira issue keys.') }

    field :jira_issue_transition_id,
      api_only: true,
      description: -> {
        s_('JiraIntegration|The ID of one or more transitions for ' \
        '[custom issue transitions](../integration/jira/issues.md#custom-issue-transitions).' \
        'Ignored when `jira_issue_transition_automatic` is enabled. Defaults to a blank string,' \
        'which disables custom transitions.')
      }

    field :issues_enabled,
      required: false,
      api_only: true,
      description: -> { s_('JiraIntegration|Enable viewing Jira issues in GitLab.') }

    field :project_keys,
      required: false,
      type: :string_array,
      api_only: true,
      description: -> {
        s_('JiraIntegration|Keys of Jira projects. When `issues_enabled` is `true`, this setting specifies ' \
        'which Jira projects to view issues from in GitLab.')
      }

    # TODO: we can probably just delegate as part of
    # https://gitlab.com/gitlab-org/gitlab/issues/29404
    # These fields are API only, so no field definition is required.
    data_field :jira_issue_transition_automatic
    data_field :project_key
    data_field :vulnerabilities_enabled
    data_field :vulnerabilities_issuetype
    data_field :customize_jira_issue_enabled

    # When these are false GitLab does not create cross reference
    # comments on Jira except when an issue gets transitioned.
    def self.supported_events
      %w[commit merge_request]
    end

    # {PROJECT-KEY}-{NUMBER} Examples: JIRA-1, PROJECT-1
    def reference_pattern(*)
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
      jira_tracker_data || build_jira_tracker_data
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

    def client(additional_options = {})
      JIRA::Client.new(options.merge(additional_options)).tap do |client|
        # Replaces JIRA default http client with our implementation
        client.request_client = Gitlab::Jira::HttpClient.new(client.options)
      end
    end

    def self.title
      'Jira issues'
    end

    def self.description
      s_("JiraService|Use Jira as this project's issue tracker.")
    end

    def self.help
      jira_doc_link_start = format('<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe,
        url: Gitlab::Routing.url_helpers.help_page_path('integration/jira/_index.md'))
      format(
        s_("JiraService|You must configure Jira before enabling this integration. " \
           "%{jira_doc_link_start}Learn more.%{link_end}"),
        jira_doc_link_start: jira_doc_link_start,
        link_end: '</a>'.html_safe)
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
          description: s_('JiraService|When a Jira issue is mentioned in a commit or merge request, a remote link ' \
                          'and comment (if enabled) will be created.')
        },
        {
          type: SECTION_TYPE_CONFIGURATION,
          title: _('Jira issue matching'),
          description: s_('Configure custom rules for Jira issue key matching')
        }
      ]

      # Currently, Jira issues are only configurable at the project and group levels.
      unless instance_level?
        sections.push({
          type: SECTION_TYPE_JIRA_ISSUES,
          title: s_('JiraService|Jira issues (optional)'),
          description: jira_issues_section_description,
          plan: 'premium'
        })

        sections.push({
          type: SECTION_TYPE_JIRA_ISSUE_CREATION,
          title: s_('JiraService|Jira issues for vulnerabilities (optional)'),
          description: s_('JiraService|Create Jira issues from GitLab to track any action taken ' \
                          'to resolve or mitigate vulnerabilities.'),
          plan: 'ultimate'
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
      return if restrict_project_key && !issue_key_allowed?(issue_key)

      expands = []
      expands << 'renderedFields' if rendered_fields
      expands << 'transitions' if transitions
      options = { expand: expands.join(',') } if expands.any?

      path = API_ENDPOINTS[:find_issue] % issue_key

      jira_request(path) { client.Issue.find(issue_key, options || {}) }
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
        return format(s_("JiraService|Events for %{noteable_model_name} are disabled."),
          noteable_model_name: mentioned_in.model_name.plural.humanize(capitalize: false))
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
      result = {}.merge!(server_info, client_info) if server_info && client_info

      success = server_info.present? && client_info.present?
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

    def testable?
      group_level? || project_level?
    end

    def project_keys_as_string
      project_keys.join(',')
    end

    private

    def jira_issue_match_regex
      jira_regex = jira_issue_regex.presence || Gitlab::Regex.jira_issue_key_regex.source

      Gitlab::UntrustedRegexp.new("\\b#{jira_issue_prefix}(?P<issue>#{jira_regex})")
    end

    def parse_project_from_issue_key(issue_key)
      issue_key.gsub(Gitlab::Regex.jira_issue_key_project_key_extraction_regex, '')
    end

    def issue_key_allowed?(issue_key)
      project_keys.blank? || project_keys.include?(parse_project_from_issue_key(issue_key))
    end

    def branch_name(commit)
      commit.first_ref_by_oid(project.repository)
    end

    def client_info
      client_url.present? ? jira_request(API_ENDPOINTS[:client_info]) { client.User.myself.attrs } : nil
    end
    strong_memoize_attr :client_info

    def server_info
      client_url.present? ? jira_request(API_ENDPOINTS[:server_info]) { client.ServerInfo.all.attrs } : nil
    end
    strong_memoize_attr :server_info

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
      path = API_ENDPOINTS[:transition_issue] % issue.id
      log_exception(e, message: 'Issue transition failed', client_url: client_url, client_path: path,
        client_status: '400')
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

      return if comment_exists?(issue, message)

      send_message(issue, message, link_props)
    end

    def comment_message(data)
      user_link = build_jira_link(data[:user][:name], data[:user][:url])

      entity = data[:entity]
      entity_ref = all_details? ? "#{entity[:name]} #{entity[:id]}" : "a #{entity[:name]}"
      entity_link = build_jira_link(entity_ref, entity[:url])

      project_link = build_jira_link(project.full_name, Gitlab::Routing.url_helpers.project_url(project))
      branch =
        if entity[:branch].present?
          format(s_('JiraService| on branch %{branch_link}'),
            branch_link: build_jira_link(entity[:branch], project_tree_url(project, entity[:branch])))
        end

      entity_message = entity[:description].presence if all_details?
      entity_message ||= entity[:title].chomp

      format(
        s_('JiraService|%{user_link} mentioned this issue in %{entity_link} of ' \
           '%{project_link}%{branch}:{quote}%{entity_message}{quote}'),
        user_link: user_link,
        entity_link: entity_link,
        project_link: project_link,
        branch: branch,
        entity_message: entity_message
      )
    end

    def build_jira_link(title, url)
      "[#{title}|#{url}]"
    end

    def has_resolution?(issue)
      issue.respond_to?(:resolution) && issue.resolution.present?
    end

    def comment_exists?(issue, message)
      path = API_ENDPOINTS[:issue_comments] % issue.id
      comments = jira_request(path) { issue.comments }

      comments.present? && comments.any? { |comment| comment.body.include?(message) }
    end

    def send_message(issue, message, remote_link_props)
      return unless client_url.present?

      path = API_ENDPOINTS[:link_remote_issue] % issue.id

      jira_request(path) do
        remote_link = find_remote_link(issue, remote_link_props[:object][:url])

        create_issue_comment(issue, message) unless remote_link
        remote_link ||= issue.remotelink.build
        remote_link.save!(remote_link_props)

        log_info("Successfully posted", client_url: client_url, client_path: path)
        "SUCCESS: Successfully posted to #{client_url}."
      end
    end

    def create_issue_comment(issue, message)
      return unless comment_on_event_enabled

      issue.comments.build.save!(body: message)
    end

    def find_remote_link(issue, url)
      path = API_ENDPOINTS[:link_remote_issue] % issue.id
      links = jira_request(path) { issue.remotelink.all }
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
      "#{Settings.gitlab.base_url.chomp('/')}#{resource}"
    end

    def build_entity_url(entity_type, entity_id)
      polymorphic_url(
        [
          project,
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
    def jira_request(path)
      yield
    rescue StandardError => e
      @error = e
      log_exception(e, message: 'Error sending message', client_url: client_url, client_path: path,
        client_status: e.try(:code))
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
        Gitlab::AppLogger.warn(message: "Jira API returned no ServerInfo, setting deployment_type from URL",
          server_info: results, url: client_url)

        return set_deployment_type_from_url
      end

      if jira_cloud?
        data_fields.deployment_cloud!
      else
        data_fields.deployment_server!
      end
    end

    def format_project_keys
      data_fields.project_keys = project_keys.compact_blank.map(&:strip).uniq
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
      description = s_('JiraService|View issues from multiple Jira projects in this GitLab project. ' \
                       'Access a read-only list of your Jira issues.')

      if project&.issues_enabled?
        description += '<br><br>'.html_safe

        gitlab_issues_link = ActionController::Base.helpers.link_to(
          '',
          edit_project_path(project, anchor: 'js-shared-permissions')
        )
        tag_pair_gitlab_issues = tag_pair(gitlab_issues_link, :link_start, :link_end)
        description += safe_format(
          s_('JiraService|If you access Jira issues in GitLab, you might want to ' \
             '%{link_start}disable GitLab issues%{link_end}.'),
          tag_pair_gitlab_issues
        )
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
