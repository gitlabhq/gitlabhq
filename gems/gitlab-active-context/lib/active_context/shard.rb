# frozen_string_literal: true

module ActiveContext
  class Shard
    def self.shard_number(number_of_shards, data)
      Digest::SHA256.hexdigest(data).hex % number_of_shards # rubocop: disable Fips/OpenSSL -- used for data distribution, not for security
    end
  end
end
