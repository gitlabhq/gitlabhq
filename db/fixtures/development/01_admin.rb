require './spec/support/sidekiq'

Gitlab::Seeder.quiet do
  User.create!(
    name: 'Administrator',
    email: 'admin@example.com',
    username: 'root',
    password: '5iveL!fe',
    admin: true,
    confirmed_at: DateTime.now
  )

  print '.'
end
