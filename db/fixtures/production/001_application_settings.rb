# frozen_string_literal: true

puts Rainbow("Creating the default ApplicationSetting record.").green
Gitlab::CurrentSettings.current_application_settings
