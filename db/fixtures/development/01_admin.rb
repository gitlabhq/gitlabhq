Gitlab::Seeder.quiet do
  User.seed do |s|
    s.id = 1
    s.name = 'Administrator'
    s.email = 'admin@example.com'
    s.username = 'root'
    s.password = '12345678'
    s.password_confirmation = '12345678'
    s.admin = true
    s.projects_limit = 100
    s.confirmed_at = DateTime.now
  end
end
