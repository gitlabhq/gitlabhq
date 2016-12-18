if ENV['GITLAB_SHARED_RUNNERS_REGISTRATION_TOKEN'].present?
  settings = ApplicationSetting.current || ApplicationSetting.create_from_defaults
  settings.set_runners_registration_token(ENV['GITLAB_SHARED_RUNNERS_REGISTRATION_TOKEN'])

  if settings.save
    puts "Saved Runner Registration Token".color(:green)
  else
    puts "Could not save Runner Registration Token".color(:red)
    puts
    settings.errors.full_messages.map do |message|
      puts "--> #{message}".color(:red)
    end
    puts
    exit 1
  end
end
