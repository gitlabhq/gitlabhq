# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class UniqueInstanceIdMetric < GenericMetric
          value do
            Gitlab::GlobalAnonymousId.instance_uuid
          end
        end
      end
    end
  end
end
