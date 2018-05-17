module EE
  module Projects
    module Settings
      module IntegrationsController
        extend ::Gitlab::Utils::Override

        private

        override :service_exceptions
        def service_exceptions
          super << slack_service
        end

        def slack_service
          if ::Gitlab::CurrentSettings.slack_app_enabled
            'slack_slash_commands'
          else
            'gitlab_slack_application'
          end
        end
      end
    end
  end
end
