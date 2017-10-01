module Ci
  class Cluster < ActiveRecord::Base
    extend Gitlab::Ci::Model

    belongs_to :project
    belongs_to :user
    belongs_to :service

    attr_encrypted :password,
      mode: :per_attribute_iv_and_salt,
      insecure_mode: true,
      key: Gitlab::Application.secrets.db_key_base,
      algorithm: 'aes-256-cbc'

    attr_encrypted :kubernetes_token,
      mode: :per_attribute_iv_and_salt,
      insecure_mode: true,
      key: Gitlab::Application.secrets.db_key_base,
      algorithm: 'aes-256-cbc'

    attr_encrypted :gcp_token,
      mode: :per_attribute_iv_and_salt,
      insecure_mode: true,
      key: Gitlab::Application.secrets.db_key_base,
      algorithm: 'aes-256-cbc'

    enum status: {
      unknown: nil,
      scheduled: 1,
      creating: 2,
      created: 3,
      errored: 4
    }

    validates :gcp_project_id, presence: true
    validates :cluster_zone, presence: true
    validates :cluster_name, presence: true
    validates :cluster_size, presence: true,
              numericality: { only_integer: true, greater_than: 0 }
    validate :restrict_modification, on: :update

    def errored!(reason)
      self.status = :errored
      self.status_reason = reason
      self.gcp_token = nil

      save!(validate: false)
    end

    def creating!(gcp_operation_id)
      self.status = :creating
      self.gcp_operation_id = gcp_operation_id

      save!(validate: false)
    end

    def on_creation?
      scheduled? || creating?
    end

    def api_url
      'https://' + endpoint
    end

    def restrict_modification
      if on_creation?
        errors.add(:base, "cannot modify during creation")
        return false
      end

      true
    end

    def destroy
      super if restrict_modification
    end
  end
end
