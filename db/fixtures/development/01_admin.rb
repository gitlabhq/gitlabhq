require './spec/support/sidekiq_middleware'

Gitlab::Seeder.quiet do
  if User.exists?(username: 'root')
    puts 'Admin user already exists, skipping'
    return
  end

  password_via_env = ENV['GITLAB_ROOT_PASSWORD'].presence
  password = password_via_env || '5iveL!fe'
  # When password is set via environment variable, don't force reset on first login.
  # Otherwise, expire password immediately to require reset.
  password_expires_at = DateTime.now unless password_via_env

  admin = User.create!(
    name: 'Administrator',
    email: "gitlab_admin_#{SecureRandom.hex(3)}@example.com",
    username: 'root',
    password: password,
    admin: true,
    confirmed_at: DateTime.now,
    password_expires_at: password_expires_at
  ) do |user|
    user.assign_personal_namespace(Organizations::Organization.default_organization)
  end

  Organizations::Organization.default_organization.add_owner(admin)

  print '.'
end
