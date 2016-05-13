HealthCheck.setup do |config|
  config.standard_checks = ['database', 'migrations', 'cache']
end
