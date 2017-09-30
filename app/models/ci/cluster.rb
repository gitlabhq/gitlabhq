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

    def error!(reason)
      update!(status: statuses[:errored],
              status_reason: reason,
              gcp_token: nil)
    end

    def on_creation?
      scheduled? || creating?
    end
  end
end
