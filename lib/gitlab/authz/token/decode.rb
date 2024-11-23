# frozen_string_literal: true

module Gitlab
  module Authz
    module Token
      class Decode
        def self.key
          raise NotImplementedError
        end

        def self.expected_type
          raise NotImplementedError
        end

        def initialize(token)
          @token = token
        end

        def jwt?
          JWT::Decode.new(token, nil, false, nil).decode_segments[1]['typ'] == 'JWT'
        rescue JWT::DecodeError
          false
        end

        def decode
          return unless self.class.key

          @payload, _header = ::JSONWebToken::RSAToken.decode(token, self.class.key.public_key)
        end

        def subject
          return unless payload

          GitlabSchema.parse_gid(payload['sub'], expected_type: self.class.expected_type)&.find
        end

        private

        attr_reader :token, :payload
      end
    end
  end
end
