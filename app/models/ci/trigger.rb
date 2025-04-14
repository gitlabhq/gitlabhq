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

    has_many :trigger_requests
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

    def set_default_values
      self.token = "#{TRIGGER_TOKEN_PREFIX}#{SecureRandom.hex(20)}" if self.token.blank?
    end

    def last_used
      if ::Feature.enabled?(:ci_read_trigger_from_ci_pipeline, project)
        pipelines.last&.created_at
      else
        trigger_requests.last&.created_at
      end
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
