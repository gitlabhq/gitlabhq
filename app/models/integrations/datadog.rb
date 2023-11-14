# frozen_string_literal: true

module Integrations
  class Datadog < Integration
    include HasWebHook

    DEFAULT_DOMAIN = 'datadoghq.com'
    URL_TEMPLATE = 'https://webhook-intake.%{datadog_domain}/api/v2/webhook'
    URL_API_KEYS_DOCS = "https://docs.#{DEFAULT_DOMAIN}/account_management/api-app-keys/"

    SUPPORTED_EVENTS = %w[
      pipeline build archive_trace
    ].freeze

    TAG_KEY_VALUE_RE = %r{\A [\w-]+ : .*\S.* \z}x

    field :datadog_site,
      exposes_secrets: true,
      placeholder: DEFAULT_DOMAIN,
      help: -> do
        ERB::Util.html_escape(
          s_('DatadogIntegration|The Datadog site to send data to. To send data to the EU site, use %{codeOpen}datadoghq.eu%{codeClose}.')
        ) % {
          codeOpen: '<code>'.html_safe,
          codeClose: '</code>'.html_safe
        }
      end

    field :api_url,
      exposes_secrets: true,
      title: -> { s_('DatadogIntegration|API URL') },
      help: -> { s_('DatadogIntegration|(Advanced) The full URL for your Datadog site.') }

    field :api_key,
      type: :password,
      title: -> { _('API key') },
      non_empty_password_title: -> { s_('ProjectService|Enter new API key') },
      non_empty_password_help: -> { s_('ProjectService|Leave blank to use your current API key') },
      help: -> do
        ERB::Util.html_escape(
          s_('DatadogIntegration|%{linkOpen}API key%{linkClose} used for authentication with Datadog.')
        ) % {
          linkOpen: %(<a href="#{URL_API_KEYS_DOCS}" target="_blank" rel="noopener noreferrer">).html_safe,
          linkClose: '</a>'.html_safe
        }
      end,
      required: true

    field :archive_trace_events,
      storage: :attribute,
      type: :checkbox,
      title: -> { _('Logs') },
      checkbox_label: -> { _('Enable logs collection') },
      help: -> { s_('When enabled, job logs are collected by Datadog and displayed along with pipeline execution traces.') }

    field :datadog_service,
      title: -> { s_('DatadogIntegration|Service') },
      placeholder: 'gitlab-ci',
      help: -> { s_('DatadogIntegration|Tag all data from this GitLab instance in Datadog. Useful when managing several self-managed deployments.') }

    field :datadog_env,
      title: -> { s_('DatadogIntegration|Environment') },
      placeholder: 'ci',
      help: -> do
        ERB::Util.html_escape(
          s_('DatadogIntegration|For self-managed deployments, set the %{codeOpen}env%{codeClose} tag for all the data sent to Datadog. %{linkOpen}How do I use tags?%{linkClose}')
        ) % {
          codeOpen: '<code>'.html_safe,
          codeClose: '</code>'.html_safe,
          linkOpen: '<a href="https://docs.datadoghq.com/getting_started/tagging/#using-tags" target="_blank" rel="noopener noreferrer">'.html_safe,
          linkClose: '</a>'.html_safe
        }
      end

    field :datadog_tags,
      type: :textarea,
      title: -> { s_('DatadogIntegration|Tags') },
      placeholder: "tag:value\nanother_tag:value",
      help: -> do
        ERB::Util.html_escape(
          s_('DatadogIntegration|Custom tags in Datadog. Enter one tag per line in the %{codeOpen}key:value%{codeClose} format. %{linkOpen}How do I use tags?%{linkClose}')
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
      validates :datadog_site, presence: true, unless: -> (obj) { obj.api_url.present? }
      validates :api_url, presence: true, unless: -> (obj) { obj.datadog_site.present? }
      validate :datadog_tags_are_valid
    end

    def initialize_properties
      super

      self.datadog_site ||= DEFAULT_DOMAIN
    end

    def self.supported_events
      SUPPORTED_EVENTS
    end

    def self.default_test_event
      'pipeline'
    end

    def configurable_events
      [] # do not allow to opt out of required hooks
      # archive_trace is opt-in but we handle it with a more detailed field below
    end

    def self.title
      'Datadog'
    end

    def self.description
      s_('DatadogIntegration|Trace your GitLab pipelines with Datadog.')
    end

    def self.help
      docs_link = ActionController::Base.helpers.link_to(
        s_('DatadogIntegration|How do I set up this integration?'),
        Rails.application.routes.url_helpers.help_page_url('integration/datadog'),
        target: '_blank', rel: 'noopener noreferrer'
      )
      s_('DatadogIntegration|Send CI/CD pipeline information to Datadog to monitor for job failures and troubleshoot performance issues. %{docs_link}').html_safe % { docs_link: docs_link.html_safe }
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
  end
end
