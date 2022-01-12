# frozen_string_literal: true

return unless Gitlab.com? || Gitlab.dev_or_test_env?

Gitlab::Application.configure do
  if Feature.feature_flags_available? && ::Feature.enabled?(:active_record_transactions_tracking, type: :ops, default_enabled: :yaml)
    Gitlab::Database::Transaction::Observer.register!
  end
end
