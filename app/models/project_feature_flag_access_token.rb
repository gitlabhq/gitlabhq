class ProjectFeatureFlagAccessToken < ActiveRecord::Base
  include TokenAuthenticatable

  belongs_to :project

  validates :project, presence: true
  validates :token, presence: true

  add_authentication_token_field :token
end
