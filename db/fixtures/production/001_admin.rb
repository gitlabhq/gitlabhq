if ENV['GITLAB_ROOT_PASSWORD'].blank?
  password = '5iveL!fe'
  expire_time = Time.now
else
  password = ENV['GITLAB_ROOT_PASSWORD']
  expire_time = nil
end

admin = User.create(
  email: "admin@example.com",
  name: "Administrator",
  username: 'root',
  password: password,
  password_expires_at: expire_time,
  theme_id: Gitlab::Themes::APPLICATION_DEFAULT

)

admin.projects_limit = 10000
admin.admin = true
admin.save!
admin.confirm

if admin.valid?
puts %Q[
Administrator account created:

login.........root
password......#{password}
]
end
