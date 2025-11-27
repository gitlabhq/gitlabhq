# frozen_string_literal: true

module ActiveContext
  class Hasher
    def self.consistent_hash(number, data)
      data = data.to_s unless data.is_a?(String)
      Digest::SHA256.hexdigest(data).hex % number # rubocop: disable Fips/OpenSSL -- used for data distribution, not for security
    end
  end
end
