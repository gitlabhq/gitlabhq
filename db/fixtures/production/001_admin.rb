password = if ENV['GITLAB_ROOT_PASSWORD'].nil? || ENV['GITLAB_ROOT_PASSWORD'].empty?
             "5iveL!fe"
           else
             ENV['GITLAB_ROOT_PASSWORD']
           end

admin = User.create(
  email: "admin@example.com",
  name: "Administrator",
  username: 'root',
  password: password,
  password_confirmation: password,
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
password......#{password}
]
end
