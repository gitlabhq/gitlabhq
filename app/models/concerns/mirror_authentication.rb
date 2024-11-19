# frozen_string_literal: true

# Mirroring may use password or SSH public-key authentication. This concern
# implements support for persisting the necessary data in a `credentials`
# serialized attribute. It also needs an `url` method to be defined
module MirrorAuthentication
  extend ActiveSupport::Concern

  included do
    validates :auth_method, inclusion: { in: %w[password ssh_public_key] }, allow_blank: true

    # We should generate a key even if there's no SSH URL present
    before_validation :generate_ssh_private_key!, if: -> {
      regenerate_ssh_private_key || (auth_method == 'ssh_public_key' && ssh_private_key.blank?)
    }

    credentials_field :auth_method, reader: false
    credentials_field :ssh_known_hosts
    credentials_field :ssh_known_hosts_verified_at
    credentials_field :ssh_known_hosts_verified_by_id
    credentials_field :ssh_private_key
    credentials_field :user
    credentials_field :password
  end

  class_methods do
    def credentials_field(name, reader: true)
      if reader
        define_method(name) do
          credentials[name] if credentials.present?
        end
      end

      define_method("#{name}=") do |value|
        credentials_will_change!

        self.credentials ||= {}

        # Removal of the password, username, etc, generally causes an update of
        # the value to the empty string. Detect and gracefully handle this case.
        if value.present?
          self.credentials[name] = value
        else
          self.credentials.delete(name)
        end
      end
    end
  end

  attr_accessor :regenerate_ssh_private_key

  def ssh_key_auth?
    ssh_mirror_url? && auth_method == 'ssh_public_key'
  end

  def password_auth?
    auth_method == 'password'
  end

  def ssh_mirror_url?
    url&.start_with?('ssh://')
  end

  def ssh_known_hosts_verified_by
    @ssh_known_hosts_verified_by ||= user_by_ssh_known_hosts_verified_by_id
  end

  def ssh_known_hosts_fingerprints
    ::SshHostKey.fingerprint_host_keys(ssh_known_hosts)
  end

  def auth_method
    auth_method = credentials.fetch(:auth_method, nil) if credentials.present?

    auth_method.presence || 'password'
  end

  def ssh_public_key
    return if ssh_private_key.blank?

    comment = "git@#{::Gitlab.config.gitlab.host}"
    SSHData::PrivateKey.parse(ssh_private_key).first.public_key.openssh(comment: comment)
  end

  def generate_ssh_private_key!
    self.ssh_private_key = SSHData::PrivateKey::RSA.generate(4096).openssl.to_pem
  end

  private

  def user_by_ssh_known_hosts_verified_by_id
    return unless ssh_known_hosts_verified_by_id

    ::User.find_by(id: ssh_known_hosts_verified_by_id)
  end
end
