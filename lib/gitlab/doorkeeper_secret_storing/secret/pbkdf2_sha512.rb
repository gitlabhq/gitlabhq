# frozen_string_literal: true
module Gitlab
  module DoorkeeperSecretStoring
    module Secret
      class Pbkdf2Sha512 < ::Doorkeeper::SecretStoring::Base
        STRETCHES = 20_000
        # An empty salt is used because we need to look tokens up solely by
        # their hashed value. Additionally, tokens are always cryptographically
        # pseudo-random and unique, therefore salting provides no
        # additional security.
        SALT = ''

        def self.transform_secret(plain_secret)
          Devise::Pbkdf2Encryptable::Encryptors::Pbkdf2Sha512.digest(plain_secret, STRETCHES, SALT)
        end

        ##
        # Determines whether this strategy supports restoring
        # secrets from the database. This allows detecting users
        # trying to use a non-restorable strategy with +reuse_access_tokens+.
        def self.allows_restoring_secrets?
          false
        end

        ##
        # Securely compare the given +input+ value with a +stored+ value
        # processed by +transform_secret+.
        def self.secret_matches?(input, stored)
          transformed_input = transform_secret(input)
          ActiveSupport::SecurityUtils.secure_compare transformed_input, stored
        end
      end
    end
  end
end
