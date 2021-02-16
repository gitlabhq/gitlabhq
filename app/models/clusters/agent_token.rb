# frozen_string_literal: true

module Clusters
  class AgentToken < ApplicationRecord
    include TokenAuthenticatable
    add_authentication_token_field :token, encrypted: :required, token_generator: -> { Devise.friendly_token(50) }

    self.table_name = 'cluster_agent_tokens'

    belongs_to :agent, class_name: 'Clusters::Agent'
    belongs_to :created_by_user, class_name: 'User', optional: true

    before_save :ensure_token
  end
end
