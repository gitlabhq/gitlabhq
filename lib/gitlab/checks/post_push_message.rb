# frozen_string_literal: true

module Gitlab
  module Checks
    class PostPushMessage
      def initialize(repository, user, protocol)
        @repository = repository
        @user = user
        @protocol = protocol
      end

      def self.fetch_message(user, repository)
        key = message_key(user, repository)

        # Also check for messages in the legacy key
        # TODO: Remove in the next release
        # https://gitlab.com/gitlab-org/gitlab/-/issues/292030
        legacy_key = legacy_message_key(user, repository) if respond_to?(:legacy_message_key)

        Gitlab::Redis::SharedState.with do |redis|
          message = redis.get(key)
          redis.del(key)

          if legacy_key
            legacy_message = redis.get(legacy_key)
            redis.del(legacy_key)
          end

          legacy_message || message
        end
      end

      def add_message
        return unless user && repository

        Gitlab::Redis::SharedState.with do |redis|
          key = self.class.message_key(user, repository)
          redis.setex(key, 5.minutes, message)
        end
      end

      def message
        raise NotImplementedError
      end

      protected

      attr_reader :repository, :user, :protocol

      delegate :project, to: :repository, allow_nil: true
      delegate :container, to: :repository, allow_nil: false

      def self.message_key(user, repository)
        raise NotImplementedError
      end

      def url_to_repo
        protocol == 'ssh' ? container.ssh_url_to_repo : container.http_url_to_repo
      end
    end
  end
end
