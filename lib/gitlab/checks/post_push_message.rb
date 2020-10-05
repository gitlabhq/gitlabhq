# frozen_string_literal: true

module Gitlab
  module Checks
    class PostPushMessage
      def initialize(repository, user, protocol)
        @repository = repository
        @user = user
        @protocol = protocol
      end

      def self.fetch_message(user_id, project_id)
        key = message_key(user_id, project_id)

        Gitlab::Redis::SharedState.with do |redis|
          message = redis.get(key)
          redis.del(key)
          message
        end
      end

      def add_message
        return unless user.present? && project.present?

        Gitlab::Redis::SharedState.with do |redis|
          key = self.class.message_key(user.id, project.id)
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

      def self.message_key(user_id, project_id)
        raise NotImplementedError
      end

      def url_to_repo
        protocol == 'ssh' ? container.ssh_url_to_repo : container.http_url_to_repo
      end
    end
  end
end
