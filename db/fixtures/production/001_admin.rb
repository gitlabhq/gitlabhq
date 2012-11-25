admin = User.create(
  email: "admin@local.host",
  name: "Administrator",
  username: 'root',
  password: "5iveL!fe",
  password_confirmation: "5iveL!fe"
)

admin.projects_limit = 10000
admin.admin = true
admin.save!

if admin.valid?
puts %q[
Administrator account created:

login.........admin@local.host
password......5iveL!fe
]
end
