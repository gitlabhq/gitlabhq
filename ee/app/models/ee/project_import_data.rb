module EE
  module ProjectImportData
    SSH_PRIVATE_KEY_OPTS = {
      type: 'RSA',
      bits: 4096
    }.freeze

    CREDENTIALS_FIELDS = %i[
      auth_method
      password
      ssh_known_hosts
      ssh_known_hosts_verified_at
      ssh_known_hosts_verified_by_id
      ssh_private_key
      user
    ].freeze

    extend ActiveSupport::Concern

    prepended do
      validates :auth_method, inclusion: { in: %w[password ssh_public_key] }, allow_blank: true

      # We should generate a key even if there's no SSH URL present
      before_validation :generate_ssh_private_key!, if: ->(data) do
        regenerate_ssh_private_key || ( auth_method == 'ssh_public_key' && ssh_private_key.blank? )
      end
    end

    attr_accessor :regenerate_ssh_private_key

    def ssh_key_auth?
      ssh_import? && auth_method == 'ssh_public_key'
    end

    def password_auth?
      auth_method == 'password'
    end

    def ssh_import?
      project&.import_url&.start_with?('ssh://')
    end

    CREDENTIALS_FIELDS.each do |name|
      define_method(name) do
        credentials[name] if credentials.present?
      end

      define_method("#{name}=") do |value|
        self.credentials ||= {}

        # Removal of the password, username, etc, generally causes an update of
        # the value to the empty string. Detect and gracefully handle this case.
        if value.present?
          self.credentials[name] = value
        else
          self.credentials.delete(name)
          nil
        end
      end
    end

    def ssh_known_hosts_verified_by
      @ssh_known_hosts_verified_by ||= ::User.find_by(id: ssh_known_hosts_verified_by_id)
    end

    def ssh_known_hosts_fingerprints
      ::SshHostKey.fingerprint_host_keys(ssh_known_hosts)
    end

    def auth_method
      auth_method = credentials.fetch(:auth_method, nil) if credentials.present?

      auth_method.presence || 'password'
    end

    def ssh_public_key
      return nil if ssh_private_key.blank?

      comment = "git@#{::Gitlab.config.gitlab.host}"
      ::SSHKey.new(ssh_private_key, comment: comment).ssh_public_key
    end

    def generate_ssh_private_key!
      self.ssh_private_key = ::SSHKey.generate(SSH_PRIVATE_KEY_OPTS).private_key
    end
  end
end
