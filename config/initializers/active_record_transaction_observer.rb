# frozen_string_literal: true

return unless Gitlab.com? || Gitlab.dev_or_test_env?

Gitlab::Application.configure do
  # When the DBMS is not available, an exception (e.g. PG::ConnectionBad) is raised
  active_db_connection = begin
    ActiveRecord::Base.connection.active? # rubocop:disable Database/MultipleDatabases
  rescue StandardError
    false
  end

  feature_flags_available = begin
    active_db_connection && Feature::FlipperFeature.table_exists?
  rescue ActiveRecord::NoDatabaseError
    false
  end

  if feature_flags_available && ::Feature.enabled?(:active_record_transactions_tracking, type: :ops)
    Gitlab::Database::Transaction::Observer.register!
  end
end
