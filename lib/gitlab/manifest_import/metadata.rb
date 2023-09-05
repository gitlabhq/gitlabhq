# frozen_string_literal: true

module Gitlab
  module ManifestImport
    class Metadata
      EXPIRY_TIME = 1.week
      KEY_PREFIX = 'manifest_import:metadata:user'

      attr_reader :user, :fallback

      def initialize(user, fallback: {})
        @user = user
        @fallback = fallback
      end

      def save(repositories, group_id)
        Gitlab::Redis::SharedState.with do |redis|
          redis.multi do |multi|
            multi.set(hashtag_key_for('repositories'), Gitlab::Json.dump(repositories), ex: EXPIRY_TIME)
            multi.set(hashtag_key_for('group_id'), group_id, ex: EXPIRY_TIME)
          end
        end
      end

      def repositories
        redis_get('repositories').then do |repositories|
          next unless repositories

          Gitlab::Json.parse(repositories).map(&:symbolize_keys)
        end || fallback[:manifest_import_repositories]
      end

      def group_id
        redis_get('group_id')&.to_i || fallback[:manifest_import_group_id]
      end

      private

      def hashtag_key_for(field)
        "#{KEY_PREFIX}:{#{user.id}}:#{field}"
      end

      def redis_get(field)
        Gitlab::Redis::SharedState.with do |redis|
          redis.get(hashtag_key_for(field))
        end
      end
    end
  end
end
