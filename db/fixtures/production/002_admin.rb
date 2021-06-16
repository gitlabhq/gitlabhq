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

# Only admins can create other admin users in Users::CreateService so to solve
# the chicken-and-egg problem, we pass a non-persisted admin user to the service.
transient_admin = User.new(admin: true)
user = Users::CreateService.new(transient_admin, user_args.merge!(skip_confirmation: true)).execute

if user.persisted?
  puts "Administrator account created:".color(:green)
  puts
  puts "login:    root".color(:green)

  if user_args.key?(:password)
    if ::Settings.gitlab['display_initial_root_password']
      puts "password: #{user_args[:password]}".color(:green)
    else
      puts "password: *** - You opted not to display initial root password to STDOUT."
    end
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
