# frozen_string_literal: true

puts "Creating the default ApplicationSetting record.".color(:green)
Gitlab::CurrentSettings.current_application_settings
