# frozen_string_literal: true

module Ci
  class Trigger < Ci::ApplicationRecord
    include Presentable
    include Limitable
    include Expirable
    include Gitlab::EncryptedAttribute

    TRIGGER_TOKEN_PREFIX = 'glptt-'

    self.limit_name = 'pipeline_triggers'
    self.limit_scope = :project

    belongs_to :project
    belongs_to :owner, class_name: "User"

    has_many :pipelines, class_name: 'Ci::Pipeline'

    validates :token, presence: true, uniqueness: true
    validates :owner, presence: true

    validate :expires_at_before_instance_max_expiry_date, on: :create

    attr_encrypted :encrypted_token_tmp,
      attribute: :encrypted_token,
      mode: :per_attribute_iv,
      algorithm: 'aes-256-gcm',
      key: :db_key_base_32,
      encode: false

    before_validation :set_default_values

    before_save :copy_token_to_encrypted_token

    scope :with_last_used, -> do
      ci_pipelines = Ci::Pipeline.arel_table
      last_used_pipelines =
        ci_pipelines
          .project(ci_pipelines[:created_at].as('last_used'))
          .where(ci_pipelines[:trigger_id].eq(arel_table[:id]))
          .order(ci_pipelines[:id].desc)
          .take(1)
      query = joins(Arel.sql("LEFT JOIN LATERAL (#{last_used_pipelines.to_sql}) last_used_pipelines ON TRUE"))
      query = query.select(default_select_columns) if query.select_values.blank?
      query.select(:last_used)
    end

    scope :with_token, ->(tokens) { where(token: Array.wrap(tokens).compact.reject(&:blank?)) }

    def set_default_values
      self.token = "#{TRIGGER_TOKEN_PREFIX}#{SecureRandom.hex(20)}" if self.token.blank?
    end

    def last_used
      # The instance should be preloaded by `.with_last_used` for performance reason
      return attributes['last_used'] if attributes.has_key?('last_used')

      pipelines.order(id: :desc).pick(:created_at)
    end

    def short_token
      token.delete_prefix(TRIGGER_TOKEN_PREFIX)[0...4] if token.present?
    end
    alias_method :trigger_short_token, :short_token

    def can_access_project?
      Ability.allowed?(self.owner, :create_build, project)
    end

    protected

    def expires_at_before_instance_max_expiry_date
      return if Feature.disabled?(:trigger_token_expiration, project)

      return unless expires_at

      max_expiry_date = Date.current.advance(days: PersonalAccessToken::MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS)
      return if expires_at.before?(max_expiry_date)

      errors.add(
        :expires_at,
        format(_("must be before %{expiry_date}"), expiry_date: max_expiry_date)
      )
    end

    private

    def copy_token_to_encrypted_token
      self.encrypted_token_tmp = token
    end
  end
end

Ci::Trigger.prepend_mod_with('Ci::Trigger')
