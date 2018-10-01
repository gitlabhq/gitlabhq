module Operations
  class FeatureFlagsAccessToken < ActiveRecord::Base
    include TokenAuthenticatable

    self.table_name = 'operations_feature_flags_access_tokens'

    belongs_to :project

    validates :project, presence: true
    validates :token, presence: true

    add_authentication_token_field :token

    before_validation :ensure_token!
  end
end
