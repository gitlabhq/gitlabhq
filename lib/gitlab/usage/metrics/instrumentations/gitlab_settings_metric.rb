# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class GitlabSettingsMetric < GenericMetric
          value do
            # rubocop:disable GitlabSecurity/PublicSend -- this is on static data and not a user-controlled input
            Gitlab::CurrentSettings.public_send(options[:setting_method])
            # rubocop:enable GitlabSecurity/PublicSend
          end
        end
      end
    end
  end
end
