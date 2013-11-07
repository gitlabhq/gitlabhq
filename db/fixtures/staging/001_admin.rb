admin = User.create(
  email: admin@local.host,
  name: Administrator,
  username: 'root',
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

login.........admin@local.host
]
end

