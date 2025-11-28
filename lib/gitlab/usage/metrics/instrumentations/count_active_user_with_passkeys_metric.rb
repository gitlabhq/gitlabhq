# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountActiveUserWithPasskeysMetric < DatabaseMetric
          operation :count

          timestamp_column(:updated_at)

          relation do
            User.where(state: 'active').where(
              id: WebauthnRegistration.passkey.select(:user_id)
            )
          end
        end
      end
    end
  end
end
