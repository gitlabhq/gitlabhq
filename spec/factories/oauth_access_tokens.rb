# == Schema Information
#
# Table name: oauth_access_tokens
#
#  id                :integer          not null, primary key
#  resource_owner_id :integer
#  application_id    :integer
#  token             :string           not null
#  refresh_token     :string
#  expires_in        :integer
#  revoked_at        :datetime
#  created_at        :datetime         not null
#  scopes            :string
#

FactoryGirl.define do
  factory :oauth_access_token do
    resource_owner
    application
    token '123456'
  end
end
