module SharedUser
  include Spinach::DSL

  step 'User "John Doe" exists' do
    user_exists("John Doe", { username: "john_doe" })
  end

  step 'User "Mary Jane" exists' do
    user_exists("Mary Jane", { username: "mary_jane" })
  end

  step 'gitlab user "Mike"' do
    create(:user, name: "Mike")
  end

  protected

  def user_exists(name, options = {})
    User.find_by(name: name) || create(:user, { name: name, admin: false }.merge(options))
  end

  step 'I have an ssh key' do
    create(:personal_key, user: @user)
  end

  step 'I have no ssh keys' do
    @user.keys.delete_all
  end
end
