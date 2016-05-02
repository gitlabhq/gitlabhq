module Jwt
  class Token
    attr_accessor :issuer, :subject, :audience, :id
    attr_accessor :issued_at, :not_before, :expire_time

    def initialize
      @payload = {}
      @id = SecureRandom.uuid
      @issued_at = Time.now
      @not_before = issued_at - 5.seconds
      @expire_time = issued_at + 1.minute
    end

    def [](key)
      @payload[key]
    end

    def []=(key, value)
      @payload[key] = value
    end

    def encoded
      raise NotImplementedError
    end

    def payload
      @payload.merge(default_payload)
    end

    def to_json
      payload.to_json
    end

    private

    def default_payload
      {
        jti: id,
        aud: audience,
        sub: subject,
        iss: issuer,
        iat: issued_at.to_i,
        nbf: not_before.to_i,
        exp: expire_time.to_i
      }.compact
    end
  end
end