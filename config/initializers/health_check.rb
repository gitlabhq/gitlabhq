HealthCheck.setup do |config|
  config.standard_checks = %w(database migrations cache)
  config.full_checks = %w(database migrations cache)

  Gitlab.ee do
    config.add_custom_check('geo') do
      Gitlab::Geo::HealthCheck.new.perform_checks
    end
  end
end
