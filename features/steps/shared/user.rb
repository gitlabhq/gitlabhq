module SharedUser
  include Spinach::DSL

  step 'Create user "John Doe"' do
    create(:user, name: "John Doe", username: "john_doe")
  end

  step 'I sign in as "John Doe"' do
    login_with(User.find_by(name: "John Doe"))
  end
end
