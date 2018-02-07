module JSONWebToken
  class HMACToken < Token
    def initialize(secret)
      super()

      @secret = secret
    end

    def encoded
      JWT.encode(payload, @secret, 'HS256')
    end
  end
end
