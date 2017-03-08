HealthCheck.setup do |config|
  config.standard_checks = %w(database migrations cache)
  config.full_checks = %w(database migrations cache)

  config.add_custom_check('geo') do
    Gitlab::Geo::HealthCheck.perform_checks
  end
end
