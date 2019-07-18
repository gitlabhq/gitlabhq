# frozen_string_literal: true

module Ci
  class Trigger < ApplicationRecord
    extend Gitlab::Ci::Model
    include Presentable

    belongs_to :project
    belongs_to :owner, class_name: "User"

    has_many :trigger_requests

    validates :token, presence: true, uniqueness: true
    validates :owner, presence: true, unless: :supports_legacy_tokens?

    before_validation :set_default_values

    def set_default_values
      self.token = SecureRandom.hex(15) if self.token.blank?
    end

    def last_trigger_request
      trigger_requests.last
    end

    def last_used
      last_trigger_request.try(:created_at)
    end

    def short_token
      token[0...4] if token.present?
    end

    def legacy?
      self.owner_id.blank?
    end

    def supports_legacy_tokens?
      Feature.enabled?(:use_legacy_pipeline_triggers, project)
    end

    def can_access_project?
      supports_legacy_tokens? && legacy? ||
        Ability.allowed?(self.owner, :create_build, project)
    end
  end
end
