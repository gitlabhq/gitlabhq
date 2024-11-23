# frozen_string_literal: true

module Gitlab
  module Authz
    module Token
      class Encode
        InvalidSubjectForTokenError = Class.new(StandardError)

        ISSUER = Settings.gitlab.host
        AUDIENCE = 'gitlab-authz-token'

        def self.key
          raise NotImplementedError
        end

        def self.expected_type
          raise NotImplementedError
        end

        def initialize(subject)
          raise InvalidSubjectForTokenError unless subject.is_a?(self.class.expected_type)

          @subject = subject
        end

        def encode(expire_time: nil)
          return unless self.class.key

          jwt_token = jwt_token(expire_time)

          ::JSONWebToken::RSAToken.encode(
            jwt_token.payload,
            self.class.key,
            self.class.key.public_key.to_jwk[:kid]
          )
        end

        private

        attr_reader :subject

        def jwt_token(expire_time)
          ::JSONWebToken::Token.new.tap do |token|
            token.subject = global_id
            token.issuer = ISSUER
            token.audience = AUDIENCE
            token.expire_time = expire_time if expire_time
            token[:version] = '0.1.0'
          end
        end

        def global_id
          gid = GlobalID.create(subject).to_s if subject
          raise InvalidSubjectForTokenError unless gid.present?

          gid
        end
      end
    end
  end
end
