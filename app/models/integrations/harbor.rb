# frozen_string_literal: true
require 'uri'

module Integrations
  class Harbor < Integration
    prop_accessor :url, :project_name, :username, :password

    validates :url, public_url: true, presence: true, addressable_url: { allow_localhost: false, allow_local_network: false }, if: :activated?
    validates :project_name, presence: true, if: :activated?
    validates :username, presence: true, if: :activated?
    validates :password, format: { with: ::Ci::Maskable::REGEX }, if: :activated?

    before_validation :reset_username_and_password

    def title
      'Harbor'
    end

    def description
      s_("HarborIntegration|Use Harbor as this project's container registry.")
    end

    def help
      s_("HarborIntegration|After the Harbor integration is activated, global variables ‘$HARBOR_USERNAME’, ‘$HARBOR_HOST’, ‘$HARBOR_OCI’, ‘$HARBOR_PASSWORD’, ‘$HARBOR_URL’ and ‘$HARBOR_PROJECT’ will be created for CI/CD use.")
    end

    class << self
      def to_param
        name.demodulize.downcase
      end

      def supported_events
        []
      end

      def supported_event_actions
        []
      end
    end

    def test(*_args)
      client.ping
    end

    def fields
      [
        {
          type: 'text',
          name: 'url',
          title: s_('HarborIntegration|Harbor URL'),
          placeholder: 'https://demo.goharbor.io',
          help: s_('HarborIntegration|Base URL of the Harbor instance.'),
          required: true
        },
        {
          type: 'text',
          name: 'project_name',
          title: s_('HarborIntegration|Harbor project name'),
          help: s_('HarborIntegration|The name of the project in Harbor.')
        },
        {
          type: 'text',
          name: 'username',
          title: s_('HarborIntegration|Harbor username'),
          required: true
        },
        {
          type: 'password',
          name: 'password',
          title: s_('HarborIntegration|Harbor password'),
          help: s_('HarborIntegration|Password for your Harbor username.'),
          non_empty_password_title: s_('HarborIntegration|Enter new Harbor password'),
          non_empty_password_help: s_('HarborIntegration|Leave blank to use your current password.'),
          required: true
        }
      ]
    end

    def ci_variables
      return [] unless activated?

      oci_uri = URI.parse(url)
      oci_uri.scheme = 'oci'
      [
        { key: 'HARBOR_URL', value: url },
        { key: 'HARBOR_HOST', value: oci_uri.host },
        { key: 'HARBOR_OCI', value: oci_uri.to_s },
        { key: 'HARBOR_PROJECT', value: project_name },
        { key: 'HARBOR_USERNAME', value: username.gsub(/^robot\$/, 'robot$$') },
        { key: 'HARBOR_PASSWORD', value: password, public: false, masked: true }
      ]
    end

    private

    def client
      @client ||= ::Gitlab::Harbor::Client.new(self)
    end

    def reset_username_and_password
      if url_changed? && !password_touched?
        self.password = nil
      end

      if url_changed? && !username_touched?
        self.username = nil
      end
    end
  end
end
