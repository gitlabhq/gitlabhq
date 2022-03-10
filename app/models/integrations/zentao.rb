# frozen_string_literal: true

module Integrations
  class Zentao < Integration
    include Gitlab::Routing

    data_field :url, :api_url, :api_token, :zentao_product_xid

    validates :url, public_url: true, presence: true, if: :activated?
    validates :api_url, public_url: true, allow_blank: true
    validates :api_token, presence: true, if: :activated?
    validates :zentao_product_xid, presence: true, if: :activated?

    # License Level: EEP_FEATURES
    def self.issues_license_available?(project)
      project&.licensed_feature_available?(:zentao_issues_integration)
    end

    def data_fields
      zentao_tracker_data || self.build_zentao_tracker_data
    end

    def title
      'ZenTao'
    end

    def description
      s_("ZentaoIntegration|Use ZenTao as this project's issue tracker.")
    end

    def help
      s_("ZentaoIntegration|Before you enable this integration, you must configure ZenTao. For more details, read the %{link_start}ZenTao integration documentation%{link_end}.") % {
        link_start: '<a href="%{url}" target="_blank" rel="noopener noreferrer">'
          .html_safe % { url: help_page_url('user/project/integrations/zentao') },
        link_end: '</a>'.html_safe
      }
    end

    def self.to_param
      name.demodulize.downcase
    end

    def test(*_args)
      client.ping
    end

    def self.supported_events
      %w()
    end

    def fields
      [
        {
          type: 'text',
          name: 'url',
          title: s_('ZentaoIntegration|ZenTao Web URL'),
          placeholder: 'https://www.zentao.net',
          help: s_('ZentaoIntegration|Base URL of the ZenTao instance.'),
          required: true
        },
        {
          type: 'text',
          name: 'api_url',
          title: s_('ZentaoIntegration|ZenTao API URL (optional)'),
          help: s_('ZentaoIntegration|If different from Web URL.')
        },
        {
          type: 'password',
          name: 'api_token',
          title: s_('ZentaoIntegration|ZenTao API token'),
          non_empty_password_title: s_('ZentaoIntegration|Enter new ZenTao API token'),
          non_empty_password_help: s_('ProjectService|Leave blank to use your current token.'),
          required: true
        },
        {
          type: 'text',
          name: 'zentao_product_xid',
          title: s_('ZentaoIntegration|ZenTao Product ID'),
          required: true
        }
      ]
    end

    private

    def client
      @client ||= ::Gitlab::Zentao::Client.new(self)
    end
  end
end

::Integrations::Zentao.prepend_mod
