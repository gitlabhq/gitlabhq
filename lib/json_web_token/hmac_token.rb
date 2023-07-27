# frozen_string_literal: true

require 'jwt'

module JSONWebToken
  class HMACToken < Token
    LEEWAY = 60
    JWT_ALGORITHM = 'HS256'

    def initialize(secret)
      super()

      @secret = secret
    end

    def self.decode(token, secret, leeway: LEEWAY, verify_iat: false)
      JWT.decode(token, secret, true, leeway: leeway, verify_iat: verify_iat, algorithm: JWT_ALGORITHM)
    end

    def encoded
      JWT.encode(payload, secret, JWT_ALGORITHM, { typ: 'JWT' })
    end

    private

    attr_reader :secret
  end
end
