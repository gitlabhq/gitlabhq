# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class InstallationTypeMetric < GenericMetric
          value do
            if Rails.env.production?
              Gitlab::INSTALLATION_TYPE
            else
              "gitlab-development-kit"
            end
          end
        end
      end
    end
  end
end
