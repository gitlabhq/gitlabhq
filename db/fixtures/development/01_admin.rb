User.seed do |s|
  s.id = 1
  s.name = "Administrator"
  s.email = "admin@example.com"
  s.username = 'root'
  s.password = "5iveL!fe"
  s.password_confirmation = "5iveL!fe"
  s.admin = true
  s.projects_limit = 100
  s.confirmed_at = DateTime.now
end
