# frozen_string_literal: true

# Shared rules for SSH certificate authority records. Fingerprint uniqueness differs
# per scope (instance-wide vs. per-namespace) and stays in the including model.
module SshCertificateValidations # rubocop:disable Gitlab/BoundedContexts -- Mirrors the un-namespaced InstanceSshCertificate model it is extracted from
  extend ActiveSupport::Concern

  include ShaAttribute

  included do
    sha256_attribute :fingerprint

    scope :for_fingerprint, ->(fingerprint) { where(fingerprint: fingerprint) }

    validates :title, presence: true, length: { maximum: 255 }

    validates :key,
      presence: true,
      ssh_key: true,
      length: { maximum: 5000 },
      format: { with: /\A(#{Gitlab::SSHPublicKey.supported_algorithms.join('|')})/ }

    validates :fingerprint, presence: true
  end
end
