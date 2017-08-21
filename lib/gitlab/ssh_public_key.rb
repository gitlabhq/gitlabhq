module Gitlab
  class SSHPublicKey
    TYPES = %w[rsa dsa ecdsa ed25519].freeze

    Technology = Struct.new(:name, :allowed_sizes)

    Technologies = [
      Technology.new('rsa',     [1024, 2048, 3072, 4096]),
      Technology.new('dsa',     [1024, 2048, 3072]),
      Technology.new('ecdsa',   [256, 384, 521]),
      Technology.new('ed25519', [256])
    ].freeze

    def self.technology_names
      Technologies.map(&:name)
    end

    def self.technology(name)
      Technologies.find { |ssh_key_technology| ssh_key_technology.name == name }
    end
    private_class_method :technology

    def self.allowed_sizes(name)
      technology(name).allowed_sizes
    end

    def self.allowed_type?(type)
      technology_names.include?(type.to_s)
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
      return unless valid?

      case key
      when OpenSSL::PKey::EC
        :ecdsa
      when OpenSSL::PKey::RSA
        :rsa
      when OpenSSL::PKey::DSA
        :dsa
      when Net::SSH::Authentication::ED25519::PubKey
        :ed25519
      else
        raise "Unsupported key type: #{key.class}"
      end
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
  end
end
