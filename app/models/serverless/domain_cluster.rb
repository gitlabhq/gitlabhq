# frozen_string_literal: true

module Serverless
  class DomainCluster < ApplicationRecord
    self.table_name = 'serverless_domain_cluster'

    HEX_REGEXP = %r{\A\h+\z}.freeze

    belongs_to :pages_domain
    belongs_to :knative, class_name: 'Clusters::Applications::Knative', foreign_key: 'clusters_applications_knative_id'
    belongs_to :creator, class_name: 'User', optional: true

    attr_encrypted :key,
      mode: :per_attribute_iv,
      key: Settings.attr_encrypted_db_key_base_32,
      algorithm: 'aes-256-gcm'

    validates :pages_domain, :knative, presence: true
    validates :uuid, presence: true, uniqueness: true, length: { is: ::Serverless::Domain::UUID_LENGTH },
              format: { with: HEX_REGEXP, message: 'only allows hex characters' }

    default_value_for(:uuid, allows_nil: false) { ::Serverless::Domain.generate_uuid }

    delegate :domain, to: :pages_domain
    delegate :cluster, to: :knative

    def self.for_uuid(uuid)
      joins(:pages_domain, :knative)
        .includes(:pages_domain, :knative)
        .find_by(uuid: uuid)
    end
  end
end
