module Gitlab
  module UserActivities
    class Activity
      attr_reader :username

      def initialize(username, time)
        @username = username
        @time = time
      end

      def last_activity_at
        @last_activity_at ||= Time.at(@time).to_s(:db)
      end
    end
  end
end
