# frozen_string_literal: true

module Clusters
  class AgentToken < ApplicationRecord
    TOKEN_PREFIX = "glagent-"

    include RedisCacheable
    include TokenAuthenticatable

    add_authentication_token_field :token,
      encrypted: :required,
      format_with_prefix: :glagent_prefix,
      routable_token: {
        payload: {
          o: ->(token_owner_record) { token_owner_record.agent.project.organization_id },
          p: ->(token_owner_record) { token_owner_record.agent.project.id }
        }
      }
    cached_attr_reader :last_used_at

    self.table_name = 'cluster_agent_tokens'

    belongs_to :agent, class_name: 'Clusters::Agent', optional: false
    belongs_to :created_by_user, class_name: 'User', optional: true
    belongs_to :project, default: -> { agent&.project }

    before_save :ensure_token

    validates :description, length: { maximum: 1024 }
    validates :name, presence: true, length: { maximum: 255 }

    scope :order_last_used_at_desc, -> { order(arel_table[:last_used_at].desc.nulls_last) }
    scope :with_status, ->(status) { where(status: status) }
    scope :active, -> { where(status: :active) }
    scope :connected, -> { active.where("last_used_at > ?", Clusters::Agent::INACTIVE_AFTER.ago) }

    enum :status, {
      active: 0,
      revoked: 1
    }

    def revoke!
      update(status: :revoked)
    end

    def to_ability_name
      :cluster
    end

    # Instance method required by TokenAuthenticatable for token generation
    def glagent_prefix
      self.class.glagent_prefix
    end

    # Class method used for token validation and as single source of truth for prefix
    def self.glagent_prefix
      ::Authn::TokenField::PrefixHelper.prepend_instance_prefix(TOKEN_PREFIX)
    end
  end
end
