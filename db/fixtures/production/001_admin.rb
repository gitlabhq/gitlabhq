user_args = {
  email:    ENV['GITLAB_ROOT_EMAIL'].presence || 'admin@example.com',
  name:     'Administrator',
  username: 'root',
  admin:    true
}

if ENV['GITLAB_ROOT_PASSWORD'].blank?
  user_args[:password_automatically_set] = true
  user_args[:force_random_password] = true
else
  user_args[:password] = ENV['GITLAB_ROOT_PASSWORD']
end

user = User.new(user_args)
user.skip_confirmation!

if user.save
  puts "Administrator account created:".color(:green)
  puts
  puts "login:    root".color(:green)

  if user_args.key?(:password)
    puts "password: #{user_args[:password]}".color(:green)
  else
    puts "password: You'll be prompted to create one on your first visit.".color(:green)
  end
  puts
else
  puts "Could not create the default administrator account:".color(:red)
  puts
  user.errors.full_messages.map do |message|
    puts "--> #{message}".color(:red)
  end
  puts

  exit 1
end
