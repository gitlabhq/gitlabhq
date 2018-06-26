class ProjectFeatureFlagsAccessToken < ActiveRecord::Base
  include TokenAuthenticatable

  belongs_to :project

  validates :project, presence: true
  validates :token, presence: true

  add_authentication_token_field :token

  before_validation :ensure_token!
end
