# frozen_string_literal: true

if ENV['ACTIVE_RECORD_DISABLE_TRANSACTION_METRICS_PATCHES'].blank?
  Gitlab::Database.install_transaction_metrics_patches!
end

return unless Gitlab.com? || Gitlab.dev_or_test_env?

if ENV['ACTIVE_RECORD_DISABLE_TRANSACTION_CONTEXT_PATCHES'].blank?
  Gitlab::Database.install_transaction_context_patches!
end
