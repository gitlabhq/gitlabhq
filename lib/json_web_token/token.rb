module JSONWebToken
  class Token
    attr_accessor :issuer, :subject, :audience, :id
    attr_accessor :issued_at, :not_before, :expire_time

    def initialize
      @id = SecureRandom.uuid
      @issued_at = Time.now
      # we give a few seconds for time shift
      @not_before = issued_at - 5.seconds
      # default 60 seconds should be more than enough for this authentication token
      @expire_time = issued_at + 1.minute
      @custom_payload = {}
    end

    def [](key)
      @custom_payload[key]
    end

    def []=(key, value)
      @custom_payload[key] = value
    end

    def encoded
      raise NotImplementedError
    end

    def payload
      @custom_payload.merge(default_payload)
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
