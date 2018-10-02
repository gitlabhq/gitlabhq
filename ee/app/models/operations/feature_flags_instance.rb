module Operations
  class FeatureFlagsInstance < ActiveRecord::Base
    include TokenAuthenticatable

    self.table_name = 'operations_feature_flags_instances'

    belongs_to :project

    validates :project, presence: true
    validates :token, presence: true

    add_authentication_token_field :token

    before_validation :ensure_token!
  end
end
