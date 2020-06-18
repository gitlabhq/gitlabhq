# frozen_string_literal: true

module Peek
  module Views
    class BulletDetailed < DetailedView
      WARNING_MESSAGE = "Unoptimized queries detected"

      def key
        'bullet'
      end

      def results
        return {} unless ::Bullet.enable?
        return {} unless calls > 0

        {
          calls: calls,
          details: details,
          warnings: [WARNING_MESSAGE]
        }
      end

      private

      def details
        notifications.map do |notification|
          # there is no public method which returns pure backtace:
          # https://github.com/flyerhzm/bullet/blob/9cda9c224a46786ecfa894480c4dd4d304db2adb/lib/bullet/notification/n_plus_one_query.rb
          backtrace = notification.body_with_caller

          {
            notification: "#{notification.title}: #{notification.body}",
            backtrace: backtrace
          }
        end
      end

      def calls
        notifications.size
      end

      def notifications
        ::Bullet.notification_collector&.collection || []
      end
    end
  end
end
