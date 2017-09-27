class OauthAccessToken < Doorkeeper::AccessToken
  belongs_to :resource_owner, class_name: 'User'
  belongs_to :application, class_name: 'Doorkeeper::Application'

  alias_method :user, :resource_owner
end
