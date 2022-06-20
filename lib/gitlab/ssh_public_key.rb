# frozen_string_literal: true

module Gitlab
  class SSHPublicKey
    Technology = Struct.new(:name, :key_class, :supported_sizes, :supported_algorithms)

    # See https://man.openbsd.org/sshd#AUTHORIZED_KEYS_FILE_FORMAT for the list of
    # supported algorithms.
    TECHNOLOGIES = [
      Technology.new(:rsa, SSHData::PublicKey::RSA, [1024, 2048, 3072, 4096], %w(ssh-rsa)),
      Technology.new(:dsa, SSHData::PublicKey::DSA, [1024, 2048, 3072], %w(ssh-dss)),
      Technology.new(:ecdsa, SSHData::PublicKey::ECDSA, [256, 384, 521], %w(ecdsa-sha2-nistp256 ecdsa-sha2-nistp384 ecdsa-sha2-nistp521)),
      Technology.new(:ed25519, SSHData::PublicKey::ED25519, [256], %w(ssh-ed25519)),
      Technology.new(:ecdsa_sk, SSHData::PublicKey::SKECDSA, [256], %w(sk-ecdsa-sha2-nistp256@openssh.com)),
      Technology.new(:ed25519_sk, SSHData::PublicKey::SKED25519, [256], %w(sk-ssh-ed25519@openssh.com))
    ].freeze

    BANNED_SSH_KEY_FINGERPRINTS = [
      # https://github.com/rapid7/ssh-badkeys/tree/master/authorized
      # banned ssh rsa keys
      "SHA256:Z+q4XhSwWY7q0BIDVPR1v/S306FjGBsid7tLq/8kIxM",
      "SHA256:uy5wXyEgbRCGsk23+J6f85om7G55Cu3UIPwC7oMZhNQ",
      "SHA256:9prMbqhS4QteoFQ1ZRJDqSBLWoHXPyKB0iWR05Ghro4",
      "SHA256:1M4RzhMyWuFS/86uPY/ce2prh/dVTHW7iD2RhpquOZA",

      # banned ssh dsa keys
      "SHA256:/JLp6z6uGE3BPcs70RQob6QOdEWQ6nDC0xY7ejPOCc0",
      "SHA256:whDP3xjKBEettbDuecxtGsfWBST+78gb6McdB9P7jCU",
      "SHA256:MEc4HfsOlMqJ3/9QMTmrKn5Xj/yfnMITMW8EwfUfTww",
      "SHA256:aPoYT2nPIfhqv6BIlbCCpbDjirBxaDFOtPfZ2K20uWw",
      "SHA256:VtjqZ5fiaeoZ3mXOYi49Lk9aO31iT4pahKFP9JPiQPc",

      # other banned ssh keys
      # https://github.com/BenBE/kompromat/commit/c8d9a05ea155a1ed609c617d4516f0ac978e8559
      "SHA256:Z+q4XhSwWY7q0BIDVPR1v/S306FjGBsid7tLq/8kIxM",

      # https://www.ctrlu.net/vuln/0006.html
      "SHA256:2ewGtK7Dc8XpnfNKShczdc8HSgoEGpoX+MiJkfH2p5I"
    ].to_set.freeze

    def self.technologies
      if Gitlab::FIPS.enabled?
        Gitlab::FIPS::SSH_KEY_TECHNOLOGIES
      else
        TECHNOLOGIES
      end
    end

    def self.technology(name)
      technologies.find { |tech| tech.name.to_s == name.to_s }
    end

    def self.technology_for_key(key)
      technologies.find { |tech| key.instance_of?(tech.key_class) }
    end

    def self.supported_types
      technologies.map(&:name)
    end

    def self.supported_sizes(name)
      technology(name).supported_sizes
    end

    def self.supported_algorithms
      technologies.flat_map { |tech| tech.supported_algorithms }
    end

    def self.supported_algorithms_for_name(name)
      technology(name).supported_algorithms
    end

    def self.sanitize(key_content)
      ssh_type, *parts = key_content.strip.split

      return key_content if parts.empty?

      parts.each_with_object(+"#{ssh_type} ").with_index do |(part, content), index|
        content << part

        if self.new(content).valid?
          break [content, parts[index + 1]].compact.join(' ') # Add the comment part if present
        elsif parts.size == index + 1 # return original content if we've reached the last element
          break key_content
        end
      end
    end

    attr_reader :key_text, :key

    def initialize(key_text)
      @key_text = key_text

      # We need to strip options to parse key with options or in known_hosts
      # format. See https://man.openbsd.org/sshd#AUTHORIZED_KEYS_FILE_FORMAT
      # and https://man.openbsd.org/sshd#SSH_KNOWN_HOSTS_FILE_FORMAT
      key_text_without_options = @key_text.to_s.match(/(\A|\s)(#{self.class.supported_algorithms.join('|')}).*/).to_s

      @key =
        begin
          SSHData::PublicKey.parse_openssh(key_text_without_options)
        rescue SSHData::DecodeError
        end
    end

    def valid?
      key.present?
    end

    def type
      technology.name if valid?
    end

    def fingerprint
      key.fingerprint(md5: true) if valid?
    end

    def fingerprint_sha256
      'SHA256:' + key.fingerprint(md5: false) if valid?
    end

    def bits
      return unless valid?

      case type
      when :rsa
        key.n.num_bits
      when :dsa
        key.p.num_bits
      when :ecdsa
        key.openssl.group.order.num_bits
      when :ed25519
        256
      when :ecdsa_sk
        256
      when :ed25519_sk
        256
      end
    end

    def banned?
      BANNED_SSH_KEY_FINGERPRINTS.include?(fingerprint_sha256)
    end

    private

    def technology
      @technology ||=
        self.class.technology_for_key(key) || raise_unsupported_key_type_error
    end

    def raise_unsupported_key_type_error
      raise("Unsupported key type: #{key.class}")
    end
  end
end
