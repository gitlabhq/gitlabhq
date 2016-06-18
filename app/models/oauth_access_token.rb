class OauthAccessToken < ActiveRecord::Base
  belongs_to :resource_owner, class_name: 'User'
  belongs_to :application, class_name: 'Doorkeeper::Application'
end
