# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module TrackUniqueActions
      KEY_EXPIRY_LENGTH = 29.days

      class << self
        def track_action(action:, author_id:, time: Time.zone.now)
          return unless Gitlab::CurrentSettings.usage_ping_enabled

          target_key = key(action, time)

          add_key(target_key, author_id)
        end

        def count_unique(action:, date_from:, date_to:)
          keys = (date_from.to_date..date_to.to_date).map { |date| key(action, date) }

          Gitlab::Redis::HLL.count(keys: keys)
        end

        private

        def key(action, date)
          year_day = date.strftime('%G-%j')
          "#{year_day}-{#{action}}"
        end

        def add_key(key, value)
          Gitlab::Redis::HLL.add(key: key, value: value, expiry: KEY_EXPIRY_LENGTH)
        end
      end
    end
  end
end
