require Rails.root.join('spec', 'support', 'login_helpers')

module SharedAuthentication
  include Spinach::DSL
  include LoginHelpers

  Given 'I sign in as a user' do
    login_as :user
  end
end
