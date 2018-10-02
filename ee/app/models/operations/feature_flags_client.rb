module Operations
  class FeatureFlagsClient < ActiveRecord::Base
    include TokenAuthenticatable

    self.table_name = 'operations_feature_flags_clients'

    belongs_to :project

    validates :project, presence: true
    validates :token, presence: true

    add_authentication_token_field :token

    before_validation :ensure_token!

    def self.find_for_project_and_token(project, token)
      return unless project
      return unless token

      find_by(token: token, project: project)
    end
  end
end
