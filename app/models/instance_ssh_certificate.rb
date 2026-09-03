# frozen_string_literal: true

class InstanceSshCertificate < ApplicationRecord # rubocop:disable Gitlab/NamespacedClass, Gitlab/BoundedContexts -- Instance-level record mirroring the top-level naming of other instance_* settings models
  include ShaAttribute

  sha256_attribute :fingerprint

  scope :for_fingerprint, ->(fingerprint) { where(fingerprint: fingerprint) }

  validates :title, presence: true, length: { maximum: 255 }

  validates :key,
    presence: true,
    ssh_key: true,
    length: { maximum: 5000 },
    format: { with: /\A(#{Gitlab::SSHPublicKey.supported_algorithms.join('|')})/ }

  validates :fingerprint,
    presence: true,
    uniqueness: { message: ->(_, _) { _('must be unique. This CA has already been configured.') } }

  def self.available?
    !Gitlab.com? && Feature.enabled?(:instance_ssh_certificates, :instance) # rubocop:disable Gitlab/AvoidGitlabInstanceChecks -- FOSS has no Saas module and this is an all-tiers CE feature
  end
end
