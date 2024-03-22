require './spec/support/sidekiq_middleware'

Gitlab::Seeder.quiet do
  if User.exists?(email: 'admin@example.com')
    puts 'Admin user already exists, skipping'
    return
  end

  User.create!(
    name: 'Administrator',
    email: 'admin@example.com',
    username: 'root',
    password: '5iveL!fe',
    admin: true,
    confirmed_at: DateTime.now,
    password_expires_at: DateTime.now
  ) do |user|
    user.assign_personal_namespace(Organizations::Organization.default_organization)
  end

  print '.'
end
