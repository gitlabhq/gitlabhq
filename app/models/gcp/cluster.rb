module Gcp
  class Cluster < ActiveRecord::Base
    extend Gitlab::Gcp::Model

    belongs_to :project, inverse_of: :cluster
    belongs_to :user
    belongs_to :service

    attr_encrypted :password,
      mode: :per_attribute_iv,
      key: Gitlab::Application.secrets.db_key_base,
      algorithm: 'aes-256-cbc'

    attr_encrypted :kubernetes_token,
      mode: :per_attribute_iv,
      key: Gitlab::Application.secrets.db_key_base,
      algorithm: 'aes-256-cbc'

    attr_encrypted :gcp_token,
      mode: :per_attribute_iv,
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
    validates :gcp_cluster_zone, presence: true
    validates :gcp_cluster_name, presence: true
    validates :gcp_cluster_size, presence: true,
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

    def created!(endpoint, ca_cert, kubernetes_token, username, password)
      self.status = :created
      self.enabled = true
      self.endpoint = endpoint
      self.ca_cert = ca_cert
      self.kubernetes_token = kubernetes_token
      self.username = username
      self.password = password
      self.service = project.find_or_initialize_service('kubernetes')
      self.gcp_token = nil
      self.gcp_operation_id = nil

      save!
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
