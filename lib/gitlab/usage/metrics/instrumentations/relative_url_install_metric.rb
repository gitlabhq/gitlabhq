# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class RelativeUrlInstallMetric < GenericMetric
          value do
            Gitlab.config.gitlab.relative_url_root.present?
          end
        end
      end
    end
  end
end
