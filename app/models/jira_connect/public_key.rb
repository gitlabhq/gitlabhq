# frozen_string_literal: true

module JiraConnect
  class PublicKey
    # Public keys are created with JWT tokens via JiraConnect::CreateAsymmetricJwtService
    # They need to be available for third party applications to verify the token.
    # This should happen right after the application received the token so public keys
    # only need to exist for a few minutes.
    REDIS_EXPIRY_TIME = 5.minutes.to_i.freeze

    attr_reader :key, :uuid

    def self.create!(key:)
      new(key: key, uuid: Gitlab::UUID.v5(SecureRandom.hex)).save!
    end

    def self.find(uuid)
      Gitlab::Redis::SharedState.with do |redis|
        key = redis.get(redis_key(uuid))

        raise ActiveRecord::RecordNotFound if key.nil?

        new(key: key, uuid: uuid)
      end
    end

    def initialize(key:, uuid:)
      key = OpenSSL::PKey.read(key) unless key.is_a?(OpenSSL::PKey::RSA)

      @key = key.to_s
      @uuid = uuid
    rescue OpenSSL::PKey::PKeyError
      raise ArgumentError, 'Invalid public key'
    end

    def save!
      Gitlab::Redis::SharedState.with do |redis|
        redis.set(self.class.redis_key(uuid), key, ex: REDIS_EXPIRY_TIME)
      end

      self
    end

    def self.redis_key(uuid)
      "JiraConnect:public_key:uuid=#{uuid}"
    end
  end
end
