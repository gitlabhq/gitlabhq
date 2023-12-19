require './spec/support/sidekiq_middleware'

Gitlab::Seeder.quiet do
  User.create!(
    name: 'Administrator',
    email: 'admin@example.com',
    username: 'root',
    password: '5iveL!fe',
    admin: true,
    confirmed_at: DateTime.now,
    password_expires_at: DateTime.now
  ) do |user|
    user.assign_personal_namespace
  end

  print '.'
end
