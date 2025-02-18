# frozen_string_literal: true

require 'uri'

module Integrations
  module Base
    module Harbor
      extend ActiveSupport::Concern

      class_methods do
        def title
          'Harbor'
        end

        def description
          s_("HarborIntegration|Use Harbor as this project's container registry.")
        end

        def help
          s_("HarborIntegration|After the Harbor integration is activated, global variables `$HARBOR_USERNAME`, " \
            "`$HARBOR_HOST`, `$HARBOR_OCI`, `$HARBOR_PASSWORD`, `$HARBOR_URL` and " \
            "`$HARBOR_PROJECT` will be created for CI/CD use.")
        end

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

      included do
        validates :url,
          public_url: true,
          presence: true,
          addressable_url: { allow_localhost: false, allow_local_network: false }, if: :activated?
        validates :project_name, presence: true, if: :activated?
        validates :username, presence: true, if: :activated?
        validates :password, format: { with: ::Ci::Maskable::REGEX }, if: :activated?

        field :url,
          title: -> { s_('HarborIntegration|Harbor URL') },
          description: -> do
            _('The base URL to the Harbor instance linked to the GitLab project. For example, `https://demo.goharbor.io`.')
          end,
          placeholder: 'https://demo.goharbor.io',
          help: -> { s_('HarborIntegration|Base URL of the Harbor instance.') },
          exposes_secrets: true,
          required: true

        field :project_name,
          title: -> { s_('HarborIntegration|Harbor project name') },
          description: -> do
            s_('HarborIntegration|The name of the project in the Harbor instance. For example, `testproject`.')
          end,
          help: -> { s_('HarborIntegration|The name of the project in Harbor.') },
          required: true

        field :username,
          title: -> { s_('HarborIntegration|Harbor username') },
          description: -> { s_('HarborIntegration|The username created in the Harbor interface.') },
          required: true

        field :password,
          type: :password,
          title: -> { s_('HarborIntegration|Harbor password') },
          description: -> { s_('HarborIntegration|The password of the user.') },
          help: -> { s_('HarborIntegration|Password for your Harbor username.') },
          non_empty_password_title: -> { s_('HarborIntegration|Enter new Harbor password') },
          non_empty_password_help: -> { s_('HarborIntegration|Leave blank to use your current password.') },
          required: true
      end

      def hostname
        Gitlab::Utils.parse_url(url).hostname
      end

      def test(*_args)
        client.check_project_availability
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
    end
  end
end
