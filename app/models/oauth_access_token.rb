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

class OauthAccessToken < ActiveRecord::Base
  belongs_to :resource_owner, class_name: 'User'
  belongs_to :application, class_name: 'Doorkeeper::Application'
end
