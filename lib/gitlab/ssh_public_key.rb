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

    def self.sanitize(key_content)
      ssh_type, *parts = key_content.strip.split

      return key_content if parts.empty?

      parts.each_with_object("#{ssh_type} ").with_index do |(part, content), index|
        content << part

        if Gitlab::SSHPublicKey.new(content).valid?
          break [content, parts[index + 1]].compact.join(' ') # Add the comment part if present
        elsif parts.size == index + 1 # return original content if we've reached the last element
          break key_content
        end
      end
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
      SSHKey.valid_ssh_public_key?(key_text)
    end

    def type
      technology.name if key.present?
    end

    def bits
      return if key.blank?

      case type
      when :rsa
        key.n&.num_bits
      when :dsa
        key.p&.num_bits
      when :ecdsa
        key.group.order&.num_bits
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
