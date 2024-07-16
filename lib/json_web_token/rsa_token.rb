# frozen_string_literal: true

module JSONWebToken
  class RSAToken < Token
    ALGORITHM = 'RS256'

    attr_reader :key_file

    def initialize(key_file)
      super()
      @key_file = key_file
    end

    def encoded
      self.class.encode(payload, key, kid)
    end

    def self.encode(payload, key, kid)
      headers = { kid: kid, typ: 'JWT' }
      JWT.encode(payload, key, ALGORITHM, headers)
    end

    def self.decode(token, key)
      JWT.decode(token, key, true, { algorithm: ALGORITHM })
    end

    private

    def key_data
      @key_data ||= File.read(key_file)
    end

    def key
      @key ||= OpenSSL::PKey::RSA.new(key_data)
    end

    def public_key
      key.public_key
    end

    def kid
      # calculate sha256 from DER encoded ASN1
      kid = Digest::SHA256.digest(public_key.to_der)

      # we encode only 30 bytes with base32
      kid = Base32.encode(kid[0..29])

      # insert colon every 4 characters
      kid.scan(/.{4}/).join(':')
    end
  end
end
