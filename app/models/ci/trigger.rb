# frozen_string_literal: true

module Ci
  class Trigger < Ci::ApplicationRecord
    include Presentable
    include Limitable
    include IgnorableColumns

    TRIGGER_TOKEN_PREFIX = 'glptt-'

    ignore_column :ref, remove_with: '16.1', remove_after: '2023-05-22'

    self.limit_name = 'pipeline_triggers'
    self.limit_scope = :project

    belongs_to :project
    belongs_to :owner, class_name: "User"

    has_many :trigger_requests

    validates :token, presence: true, uniqueness: true
    validates :owner, presence: true

    attr_encrypted :encrypted_token_tmp,
      attribute: :encrypted_token,
      mode: :per_attribute_iv,
      algorithm: 'aes-256-gcm',
      key: Settings.attr_encrypted_db_key_base_32,
      encode: false

    before_validation :set_default_values

    before_save :copy_token_to_encrypted_token

    def set_default_values
      self.token = "#{TRIGGER_TOKEN_PREFIX}#{SecureRandom.hex(20)}" if self.token.blank?
    end

    def last_trigger_request
      trigger_requests.last
    end

    def last_used
      last_trigger_request.try(:created_at)
    end

    def short_token
      token.delete_prefix(TRIGGER_TOKEN_PREFIX)[0...4] if token.present?
    end

    def can_access_project?
      Ability.allowed?(self.owner, :create_build, project)
    end

    private

    def copy_token_to_encrypted_token
      self.encrypted_token_tmp = token
    end
  end
end

Ci::Trigger.prepend_mod_with('Ci::Trigger')
