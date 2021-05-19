# frozen_string_literal: true

module Clusters
  class AgentToken < ApplicationRecord
    include RedisCacheable
    include TokenAuthenticatable

    add_authentication_token_field :token, encrypted: :required, token_generator: -> { Devise.friendly_token(50) }
    cached_attr_reader :last_used_at

    self.table_name = 'cluster_agent_tokens'

    # The `UPDATE_USED_COLUMN_EVERY` defines how often the token DB entry can be updated
    UPDATE_USED_COLUMN_EVERY = (40.minutes..55.minutes).freeze

    belongs_to :agent, class_name: 'Clusters::Agent', optional: false
    belongs_to :created_by_user, class_name: 'User', optional: true

    before_save :ensure_token

    validates :description, length: { maximum: 1024 }
    validates :name, presence: true, length: { maximum: 255 }

    scope :order_last_used_at_desc, -> { order(::Gitlab::Database.nulls_last_order('last_used_at', 'DESC')) }

    def track_usage
      track_values = { last_used_at: Time.current.utc }

      cache_attributes(track_values)

      # Use update_column so updated_at is skipped
      update_columns(track_values) if can_update_track_values?
    end

    private

    def can_update_track_values?
      # Use a random threshold to prevent beating DB updates.
      last_used_at_max_age = Random.rand(UPDATE_USED_COLUMN_EVERY)

      real_last_used_at = read_attribute(:last_used_at)

      # Handle too many updates from high token traffic
      real_last_used_at.nil? ||
        (Time.current - real_last_used_at) >= last_used_at_max_age
    end
  end
end
