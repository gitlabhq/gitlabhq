# frozen_string_literal: true

return unless Gitlab.com? || Gitlab.dev_or_test_env?

def feature_flags_available?
  # When the DBMS is not available, an exception (e.g. PG::ConnectionBad) is raised
  active_db_connection = ActiveRecord::Base.connection.active? rescue false

  active_db_connection && Feature::FlipperFeature.table_exists?
rescue ActiveRecord::NoDatabaseError
  false
end

Gitlab::Application.configure do
  if feature_flags_available? && ::Feature.enabled?(:active_record_transactions_tracking, type: :ops, default_enabled: :yaml)
    Gitlab::Database::Transaction::Observer.register!
  end
end
