# frozen_string_literal: true

module Tasks
  module Gitlab
    module Permissions
      module Graphql
        module SkipReasons
          REASON_LABELS = {
            parent_authorizes: 'Parent type authorizes',
            subscription_root: 'Subscription root type; the payload type authorizes each delivery',
            child_authorizes: 'Child type authorizes',
            external_service_authorizes: 'An external service authorizes each operation'
          }.freeze

          VALID_SKIP_REASONS = REASON_LABELS.keys.freeze
        end
      end
    end
  end
end
