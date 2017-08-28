module Gitlab
  class SSHPublicKey
    Technology = Struct.new(:name, :key_class, :supported_sizes)

    Technologies = [
      Technology.new(:rsa, OpenSSL::PKey::RSA, [1024, 2048, 3072, 4096]),
      Technology.new(:dsa, OpenSSL::PKey::DSA, [1024, 2048, 3072]),
      Technology.new(:ecdsa, OpenSSL::PKey::EC, [256, 384, 521]),
      Technology.new(:ed25519, Net::SSH::Authentication::ED25519::PubKey, [256])
    ].freeze

    def self.technology(name)
      Technologies.find { |tech| tech.name.to_s == name.to_s }
    end

    def self.technology_for_key(key)
      Technologies.find { |tech| key.is_a?(tech.key_class) }
    end

    def self.supported_sizes(name)
      technology(name)&.supported_sizes
    end

    attr_reader :key_text, :key

    # Unqualified MD5 fingerprint for compatibility
    delegate :fingerprint, to: :key, allow_nil: true

    def initialize(key_text)
      @key_text = key_text

      @key =
        begin
          Net::SSH::KeyFactory.load_data_public_key(key_text)
        rescue StandardError, NotImplementedError
        end
    end

    def valid?
      key.present?
    end

    def type
      technology.name if valid?
    end

    def bits
      return unless valid?

      case type
      when :rsa
        key.n.num_bits
      when :dsa
        key.p.num_bits
      when :ecdsa
        key.group.order.num_bits
      when :ed25519
        256
      else
        raise "Unsupported key type: #{type}"
      end
    end

    private

    def technology
      @technology ||=
        self.class.technology_for_key(key) || raise("Unsupported key type: #{key.class}")
    end
  end
end
