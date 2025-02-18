# frozen_string_literal: true

module Gitlab
  module Sessions
    module CacheStoreCoder
      extend self

      if ::Gitlab.next_rails?
        include ActiveSupport::Cache::SerializerWithFallback[:marshal_6_1]
      else
        include ActiveSupport::Cache::Coders::Rails61Coder
      end

      def load(payload)
        unmarshalled = super

        return unmarshalled if unmarshalled.is_a?(ActiveSupport::Cache::Entry)

        # The session payload coming from the old `RedisStore` is a hash,
        # whereas payload from `CacheStore` expects the hash to be wrapped in `ActiveSupport::Cache::Entry`.
        # The payload here is re-wrapped to make old sessions compatible when read by `CacheStore`.
        # https://gitlab.com/gitlab-com/gl-infra/data-access/durability/team/-/issues/35#note_2278902354
        ActiveSupport::Cache::Entry.new(unmarshalled)
      end
    end
  end
end
