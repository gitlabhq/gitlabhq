module Gitlab
  module CycleAnalytics
    class AuthorUpdater
      def self.update!(*args)
        new(*args).update!
      end

      def initialize(event_result)
        @event_result = event_result
      end

      def update!
        @event_result.each do |event|
          event['author'] = users[event.delete('author_id').to_i].first
        end
      end

      def user_ids
        @event_result.map { |event| event['author_id'] }
      end

      def users
        @users ||= User.find(user_ids).group_by { |user| user['id'] }
      end
    end
  end
end
