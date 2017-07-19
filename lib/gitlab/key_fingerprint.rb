module Gitlab
  class KeyFingerprint
    attr_reader :key, :ssh_key

    # Unqualified MD5 fingerprint for compatibility
    delegate :fingerprint, to: :ssh_key, allow_nil: true

    def initialize(key)
      @key = key

      @ssh_key =
        begin
          Net::SSH::KeyFactory.load_data_public_key(key)
        rescue Net::SSH::Exception, NotImplementedError
        end
    end

    def valid?
      ssh_key.present?
    end

    def type
      return unless valid?

      parts = ssh_key.ssh_type.split('-')
      parts.shift if parts[0] == 'ssh'

      parts[0].upcase
    end

    def bits
      return unless valid?

      case type
      when 'RSA'
        ssh_key.n.num_bits
      when 'DSS', 'DSA'
        ssh_key.p.num_bits
      when 'ECDSA'
        ssh_key.group.order.num_bits
      when 'ED25519'
        256
      else
        raise "Unsupported key type: #{type}"
      end
    end
  end
end
