# frozen_string_literal: true

module Gitlab
  module HashDigest
    # Used for rolling out to use OpenSSL::Digest::SHA256
    # for ActiveSupport::Digest
    class Facade
      class << self
        def hexdigest(...)
          hash_digest_class.hexdigest(...)
        end

        def hash_digest_class
          if use_sha256?
            ::OpenSSL::Digest::SHA256
          else
            ::Digest::MD5 # rubocop:disable Fips/MD5
          end
        end

        def use_sha256?
          return false unless Feature.feature_flags_available?

          Feature.enabled?(:active_support_hash_digest_sha256)
        end
      end
    end
  end
end
