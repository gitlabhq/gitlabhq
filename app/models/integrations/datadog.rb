# frozen_string_literal: true

module Integrations
  class Datadog < Integration
    include HasWebHook

    DEFAULT_DOMAIN = 'datadoghq.com'
    URL_TEMPLATE = 'https://webhook-intake.%{datadog_domain}/api/v2/webhook'
    URL_API_KEYS_DOCS = "https://docs.#{DEFAULT_DOMAIN}/account_management/api-app-keys/"
    CI_LOGS_DOCS = "https://docs.#{DEFAULT_DOMAIN}/continuous_integration/pipelines/gitlab/?tab=gitlabcom#collect-job-logs"
    CI_VISIBILITY_PRICING = "https://www.#{DEFAULT_DOMAIN}/pricing/?product=ci-pipeline-visibility#products"
    SITES_DOCS = "https://docs.#{DEFAULT_DOMAIN}/getting_started/site/"

    SUPPORTED_EVENTS = %w[
      pipeline build archive_trace push merge_request note tag_push subgroup project
    ].freeze

    TAG_KEY_VALUE_RE = %r{\A [\w-]+ : .*\S.* \z}x

    # The config is divided in two sections:
    # - General account configuration, which allows setting up a Datadog site and API key
    # - CI Visibility configuration, which is specific to job & pipeline events
    def sections
      [
        {
          type: SECTION_TYPE_CONNECTION,
          title: s_('DatadogIntegration|Datadog account'),
          description: help
        },
        {
          type: SECTION_TYPE_CONFIGURATION,
          title: s_('DatadogIntegration|CI Visibility'),
          description: s_('DatadogIntegration|Additionally, enable CI Visibility to send pipeline information to Datadog to monitor for job failures and troubleshoot performance issues.')
        }
      ]
    end

    # General account configuration
    field :datadog_site,
      exposes_secrets: true,
      section: SECTION_TYPE_CONNECTION,
      placeholder: DEFAULT_DOMAIN,
      help: -> do
        docs_link = ActionController::Base.helpers.link_to('', SITES_DOCS, target: '_blank', rel: 'noopener noreferrer')
        tag_pair_docs_link = tag_pair(docs_link, :link_start, :link_end)

        safe_format(s_('DatadogIntegration|Datadog site to send data to. Learn more about Datadog sites in the %{link_start}documentation%{link_end}.'), tag_pair_docs_link)
      end

    field :api_url,
      exposes_secrets: true,
      section: SECTION_TYPE_CONNECTION,
      title: -> { s_('DatadogIntegration|API URL') },
      help: -> { s_('DatadogIntegration|Full URL of your Datadog site. Only required if you do not use a standard Datadog site.') }

    field :api_key,
      type: :password,
      section: SECTION_TYPE_CONNECTION,
      title: -> { _('API key') },
      non_empty_password_title: -> { s_('ProjectService|Enter new API key') },
      non_empty_password_help: -> { s_('ProjectService|Leave blank to use your current API key') },
      help: -> do
        docs_link = ActionController::Base.helpers.link_to('', URL_API_KEYS_DOCS, target: '_blank', rel: 'noopener noreferrer')
        tag_pair_docs_link = tag_pair(docs_link, :link_start, :link_end)

        safe_format(s_('DatadogIntegration|%{link_start}API key%{link_end} used for authentication with Datadog.'), tag_pair_docs_link)
      end,
      required: true

    # CI Visibility section
    field :datadog_ci_visibility,
      type: :checkbox,
      section: SECTION_TYPE_CONFIGURATION,
      title: -> { s_('DatadogIntegration|Enabled') },
      checkbox_label: -> { s_('DatadogIntegration|Enable CI Visibility') },
      description: -> { _('Enable CI Visibility') },
      help: -> do
        docs_link = ActionController::Base.helpers.link_to('', CI_VISIBILITY_PRICING, target: '_blank', rel: 'noopener noreferrer')
        tag_pair_docs_link = tag_pair(docs_link, :link_start, :link_end)

        safe_format(s_('DatadogIntegration|When enabled, pipelines and jobs are collected, and Datadog will display pipeline execution traces. Note that CI Visibility is priced per committers, see our %{link_start}pricing page%{link_end}.'), tag_pair_docs_link)
      end

    field :archive_trace_events,
      storage: :attribute,
      type: :checkbox,
      section: SECTION_TYPE_CONFIGURATION,
      title: -> { _('Logs') },
      checkbox_label: -> { _('Enable Pipeline Job logs collection') },
      help: -> do
        docs_link = ActionController::Base.helpers.link_to('', CI_LOGS_DOCS, target: '_blank', rel: 'noopener noreferrer')
        tag_pair_docs_link = tag_pair(docs_link, :link_start, :link_end)

        safe_format(s_('DatadogIntegration|When enabled, pipeline job logs are collected by Datadog and displayed along with pipeline execution traces. This requires CI Visibility to be enabled. Note that pipeline job logs are priced like regular Datadog logs. Learn more %{link_start}here%{link_end}.'), tag_pair_docs_link)
      end

    field :datadog_service,
      title: -> { s_('DatadogIntegration|Service') },
      section: SECTION_TYPE_CONFIGURATION,
      placeholder: 'gitlab-ci',
      help: -> { s_('DatadogIntegration|Tag all pipeline data from this GitLab instance in Datadog. Can be used when managing several self-managed deployments.') }

    field :datadog_env,
      title: -> { s_('DatadogIntegration|Environment') },
      section: SECTION_TYPE_CONFIGURATION,
      placeholder: 'ci',
      description: -> { _('For self-managed deployments, `env` tag for all the data sent to Datadog.') },
      help: -> do
        ERB::Util.html_escape(
          s_('DatadogIntegration|For self-managed deployments, set the %{codeOpen}env%{codeClose} tag for all the pipeline data sent to Datadog. %{linkOpen}How do I use tags?%{linkClose}')
        ) % {
          codeOpen: '<code>'.html_safe,
          codeClose: '</code>'.html_safe,
          linkOpen: '<a href="https://docs.datadoghq.com/getting_started/tagging/#using-tags" target="_blank" rel="noopener noreferrer">'.html_safe,
          linkClose: '</a>'.html_safe
        }
      end

    field :datadog_tags,
      type: :textarea,
      section: SECTION_TYPE_CONFIGURATION,
      title: -> { s_('DatadogIntegration|Tags') },
      placeholder: "tag:value\nanother_tag:value",
      description: -> { _('Custom tags in Datadog. Specify one tag per line in the format `key:value\nkey2:value2`.') },
      help: -> do
        ERB::Util.html_escape(
          s_('DatadogIntegration|Custom tags for pipeline data in Datadog. Enter one tag per line in the %{codeOpen}key:value%{codeClose} format. %{linkOpen}How do I use tags?%{linkClose}')
        ) % {
          codeOpen: '<code>'.html_safe,
          codeClose: '</code>'.html_safe,
          linkOpen: '<a href="https://docs.datadoghq.com/getting_started/tagging/#using-tags" target="_blank" rel="noopener noreferrer">'.html_safe,
          linkClose: '</a>'.html_safe
        }
      end

    before_validation :strip_properties

    with_options if: :activated? do
      validates :api_key, presence: true, format: { with: /\A\w+\z/ }
      validates :datadog_site, format: { with: %r{\A\w+([-.]\w+)*\.[a-zA-Z]{2,5}(:[0-9]{1,5})?\z}, allow_blank: true }
      validates :api_url, public_url: { allow_blank: true }
      validates :datadog_site, presence: true, unless: ->(obj) { obj.api_url.present? }
      validates :api_url, presence: true, unless: ->(obj) { obj.datadog_site.present? }
      validates :datadog_ci_visibility, inclusion: [true, false]
      validate :datadog_tags_are_valid
      validate :logs_requires_ci_vis
    end

    def initialize_properties
      super

      self.datadog_site ||= DEFAULT_DOMAIN

      # Previous versions of the integration don't have the datadog_ci_visibility boolean stored in the configuration.
      # Since the previous default was for this to be enabled, we want this attribute to be initialized to true
      # if the integration was previously active. Otherwise, it should default to false.
      if datadog_ci_visibility.nil?
        self.datadog_ci_visibility = active
      end
    end

    attribute :pipeline_events, default: false
    attribute :job_events, default: false
    before_save :update_pipeline_events

    def update_pipeline_events
      # pipeline and job events are opt-in, controlled by a single datadog_ci_visibility checkbox
      unless datadog_ci_visibility.nil?
        self.job_events = datadog_ci_visibility
        self.pipeline_events = datadog_ci_visibility
      end
    end

    def self.supported_events
      SUPPORTED_EVENTS
    end

    def self.default_test_event
      'push'
    end

    def configurable_events
      [] # do not allow to opt out of required hooks
      # archive_trace is opt-in but we handle it with a more detailed field below
    end

    def self.title
      'Datadog'
    end

    def self.description
      s_('DatadogIntegration|Connect your projects to Datadog and trace your GitLab pipelines.')
    end

    def self.help
      build_help_page_url(
        'integration/datadog.md',
        s_('DatadogIntegration|Connect your GitLab projects to your Datadog account to synchronize repository metadata and enrich telemetry on your Datadog account.'),
        _('How do I set up this integration?')
      )
    end

    def self.to_param
      'datadog'
    end

    override :hook_url
    def hook_url
      url = api_url.presence || sprintf(URL_TEMPLATE, datadog_domain: datadog_domain)
      url = URI.parse(url)
      query = {
        "dd-api-key" => 'THIS_VALUE_WILL_BE_REPLACED',
        service: datadog_service.presence,
        env: datadog_env.presence,
        tags: datadog_tags_query_param.presence
      }.compact
      url.query = query.to_query
      url.to_s.gsub('THIS_VALUE_WILL_BE_REPLACED', '{api_key}')
    end

    def url_variables
      { 'api_key' => api_key }
    end

    def execute(data)
      return unless supported_events.include?(data[:object_kind])

      object_kind = data[:object_kind]
      object_kind = 'job' if object_kind == 'build'
      data = hook_data(data, object_kind)
      execute_web_hook!(data, "#{object_kind} hook")
    end

    def test(data)
      result = execute(data)

      {
        success: (200..299).cover?(result.payload[:http_status]),
        result: result.message
      }
    end

    private

    def datadog_domain
      # Transparently ignore "app" prefix from datadog_site as the official docs table in
      # https://docs.datadoghq.com/getting_started/site/ is confusing for internal URLs.
      # US3 needs to keep a prefix but other datacenters cannot have the listed "app" prefix
      datadog_site.delete_prefix("app.")
    end

    def hook_data(data, object_kind)
      if object_kind == 'pipeline' && data.respond_to?(:with_retried_builds)
        return data.with_retried_builds
      end

      data
    end

    def strip_properties
      datadog_service.strip! if datadog_service && !datadog_service.frozen?
      datadog_env.strip! if datadog_env && !datadog_env.frozen?
      datadog_tags.strip! if datadog_tags && !datadog_tags.frozen?
    end

    def datadog_tags_are_valid
      return unless datadog_tags

      unless datadog_tags.split("\n").select(&:present?).all? { _1 =~ TAG_KEY_VALUE_RE }
        errors.add(:datadog_tags, s_("DatadogIntegration|have an invalid format"))
      end
    end

    def datadog_tags_query_param
      return unless datadog_tags

      datadog_tags.split("\n").filter_map do |tag|
        tag.strip!

        next if tag.blank?

        if tag.include?(',')
          "\"#{tag}\""
        else
          tag
        end
      end.join(',')
    end

    def logs_requires_ci_vis
      if archive_trace_events && !datadog_ci_visibility
        errors.add(:archive_trace_events, s_("DatadogIntegration|requires CI Visibility to be enabled"))
      end
    end
  end
end
