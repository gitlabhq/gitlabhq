# frozen_string_literal: true

module Gitlab
  module Serverless
    class Domain
      UUID_LENGTH = 14

      def self.generate_uuid
        SecureRandom.hex(UUID_LENGTH / 2)
      end
    end
  end
end
