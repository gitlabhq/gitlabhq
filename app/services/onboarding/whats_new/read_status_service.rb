# frozen_string_literal: true

module Onboarding
  module WhatsNew
    class ReadStatusService
      def initialize(user_id, version_digest)
        @user_id = user_id
        @version_digest = version_digest
      end

      def mark_article_as_read(article_id)
        @article_id = article_id.to_i

        return ServiceResponse.error(message: 'invalid article id') unless valid_id?

        Gitlab::Redis::SharedState.with do |redis|
          return ServiceResponse.error(message: 'article already marked as read') if already_read? # rubocop:disable Cop/AvoidReturnFromBlocks -- break/next doesn't work here

          redis.multi do |multi|
            multi.sadd(redis_set_key, article_id)
            multi.expire(redis_set_key, 2.months.to_i)
          end
        end

        ServiceResponse.success
      end

      def most_recent_version_read_articles
        Gitlab::Redis::SharedState.with do |redis|
          redis.smembers(redis_set_key).map(&:to_i)
        end
      end

      private

      attr_reader :user_id, :version_digest, :article_id

      def redis_set_key
        "whats_new:#{version_digest}:user:#{user_id}:read_articles"
      end

      def already_read?
        Gitlab::Redis::SharedState.with do |redis|
          redis.sismember(redis_set_key, article_id)
        end
      end

      def valid_id?
        article_id.between?(1, ReleaseHighlight.most_recent_item_count)
      end
    end
  end
end
