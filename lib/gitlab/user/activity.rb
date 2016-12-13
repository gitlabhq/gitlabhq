module Gitlab
  module User
    class Activity
      attr_reader :username

      def self.from_array(activities)
        activities.map { |activity| new(*activity) }
      end

      def initialize(username, time)
        @username = username
        @time = time
      end

      def date
        @date ||= Time.at(@time).utc.to_datetime
      end
    end
  end
end
