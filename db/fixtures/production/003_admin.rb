user_args = {
  email:    ENV['GITLAB_ROOT_EMAIL'].presence || "gitlab_admin_#{SecureRandom.hex(3)}@example.com",
  name:     'Administrator',
  username: 'root',
  admin:    true,
  organization_id: Organizations::Organization.default_organization.id
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
response = Users::CreateService.new(transient_admin, user_args.merge!(skip_confirmation: true)).execute

if response.success?
  user = response.payload[:user]

  Organizations::Organization.default_organization.add_owner(user)

  puts Rainbow("Administrator account created:").green
  puts
  puts Rainbow("login:    root").green

  if user_args.key?(:password)
    if ::Settings.gitlab['display_initial_root_password']
      puts Rainbow("password: #{user_args[:password]}").green
    else
      puts Rainbow("password: ******").green
    end
  else
    puts Rainbow("password: You'll be prompted to create one on your first visit.").green
  end
  puts
else
  puts Rainbow("Could not create the default administrator account:").red
  puts
  puts Rainbow("--> #{response.message}").red
  puts

  exit 1
end
