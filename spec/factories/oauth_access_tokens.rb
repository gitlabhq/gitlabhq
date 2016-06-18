FactoryGirl.define do
  factory :oauth_access_token do
    resource_owner
    application
    token '123456'
  end
end
