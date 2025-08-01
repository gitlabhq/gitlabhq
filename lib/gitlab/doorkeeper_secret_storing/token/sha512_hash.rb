# frozen_string_literal: true

module Gitlab
  module DoorkeeperSecretStoring
    module Token
      class Sha512Hash < ::Doorkeeper::SecretStoring::Base
        def self.transform_secret(plain_secret)
          Digest::SHA512.hexdigest plain_secret
        end

        ##
        # Determines whether this strategy supports restoring
        # secrets from the database. This allows detecting users
        # trying to use a non-restorable strategy with +reuse_access_tokens+.
        def self.allows_restoring_secrets?
          false
        end
      end
    end
  end
end
