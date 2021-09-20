# frozen_string_literal: true

module Integrations
  class Zentao < Integration
    data_field :url, :api_url, :api_token, :zentao_product_xid

    validates :url, public_url: true, presence: true, if: :activated?
    validates :api_url, public_url: true, allow_blank: true
    validates :api_token, presence: true, if: :activated?
    validates :zentao_product_xid, presence: true, if: :activated?

    def data_fields
      zentao_tracker_data || self.build_zentao_tracker_data
    end

    def title
      self.class.name.demodulize
    end

    def description
      s_("ZentaoIntegration|Use Zentao as this project's issue tracker.")
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

    def self.supported_event_actions
      %w()
    end

    def fields
      [
        {
          type: 'text',
          name: 'url',
          title: s_('ZentaoIntegration|Zentao Web URL'),
          placeholder: 'https://www.zentao.net',
          help: s_('ZentaoIntegration|Base URL of the Zentao instance.'),
          required: true
        },
        {
          type: 'text',
          name: 'api_url',
          title: s_('ZentaoIntegration|Zentao API URL (optional)'),
          help: s_('ZentaoIntegration|If different from Web URL.')
        },
        {
          type: 'password',
          name: 'api_token',
          title: s_('ZentaoIntegration|Zentao API token'),
          non_empty_password_title: s_('ZentaoIntegration|Enter API token'),
          required: true
        },
        {
          type: 'text',
          name: 'zentao_product_xid',
          title: s_('ZentaoIntegration|Zentao Product ID'),
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
