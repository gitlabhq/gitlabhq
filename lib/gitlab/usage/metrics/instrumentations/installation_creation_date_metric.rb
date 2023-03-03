# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class InstallationCreationDateMetric < GenericMetric
          value do
            User.where(id: 1).pick(:created_at)
          end
        end
      end
    end
  end
end
