require 'securerandom'

password = SecureRandom.urlsafe_base64(16)

admin = User.create(
  :email => "admin@local.host",
  :name => "Administrator",
  :password => password,
  :password_confirmation => password
)

admin.projects_limit = 10000
admin.admin = true
admin.save!

if admin.valid?
puts %q[
Administrator account created:

login.........admin@local.host
password......] + password

end
