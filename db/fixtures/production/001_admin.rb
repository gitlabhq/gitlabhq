admin = User.create(
  email: "admin@example.com",
  name: "Administrator",
  username: 'root',
  password: "5iveL!fe",
  password_confirmation: "5iveL!fe",
  password_expires_at: Time.now,
  theme_id: Gitlab::Theme::MARS

)

admin.projects_limit = 10000
admin.admin = true
admin.save!
admin.confirm!

if admin.valid?
puts %q[
Administrator account created:

login.........root
password......5iveL!fe
]
end
