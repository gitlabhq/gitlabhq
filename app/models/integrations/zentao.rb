# frozen_string_literal: true

module Integrations
  class Zentao < Integration
    include Base::IssueTracker
    include Gitlab::Routing

    self.field_storage = :data_fields

    field :url,
      title: -> { s_('ZentaoIntegration|ZenTao Web URL') },
      placeholder: 'https://www.zentao.net',
      help: -> { s_('ZentaoIntegration|Base URL of the ZenTao instance.') },
      exposes_secrets: true,
      required: true

    field :api_url,
      title: -> { s_('ZentaoIntegration|ZenTao API URL (optional)') },
      help: -> { s_('ZentaoIntegration|If different from Web URL.') },
      exposes_secrets: true

    field :api_token,
      type: :password,
      title: -> { s_('ZentaoIntegration|ZenTao API token') },
      non_empty_password_title: -> { s_('ZentaoIntegration|Enter new ZenTao API token') },
      non_empty_password_help: -> { s_('ProjectService|Leave blank to use your current token.') },
      required: true

    field :zentao_product_xid,
      title: -> { s_('ZentaoIntegration|ZenTao Product ID') },
      required: true

    validates :url, public_url: true, presence: true, if: :activated?
    validates :api_url, public_url: true, allow_blank: true
    validates :api_token, presence: true, if: :activated?
    validates :zentao_product_xid, presence: true, if: :activated?

    def avatar_url
      ActionController::Base.helpers.image_path('logos/zentao.svg')
    end

    def self.issues_license_available?(project)
      project&.licensed_feature_available?(:zentao_issues_integration)
    end

    def data_fields
      zentao_tracker_data || self.build_zentao_tracker_data
    end

    alias_method :project_url, :url

    def set_default_data
      return unless issues_tracker.present?

      return if url

      data_fields.url ||= issues_tracker['url']
      data_fields.api_url ||= issues_tracker['api_url']
    end

    def self.title
      'ZenTao'
    end

    def self.description
      s_("ZentaoIntegration|Use ZenTao as this project's issue tracker.")
    end

    def self.help
      s_("ZentaoIntegration|Before you enable this integration, you must configure ZenTao. For more details, read the %{link_start}ZenTao integration documentation%{link_end}.") % {
        link_start: '<a href="%{url}" target="_blank" rel="noopener noreferrer">'
          .html_safe % { url: Rails.application.routes.url_helpers.help_page_url('user/project/integrations/zentao.md') },
        link_end: '</a>'.html_safe
      }
    end

    def client_url
      api_url.presence || url
    end

    def self.to_param
      name.demodulize.downcase
    end

    def test(*_args)
      client.ping
    end

    def self.supported_events
      %w[]
    end

    private

    def client
      @client ||= ::Gitlab::Zentao::Client.new(self)
    end
  end
end

::Integrations::Zentao.prepend_mod
