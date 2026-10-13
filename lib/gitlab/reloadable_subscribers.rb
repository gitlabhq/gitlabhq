# frozen_string_literal: true

module Gitlab
  # ActiveSupport::Subscriber subclasses call `attach_to` in their class body,
  # so every code reload in development attaches another instance while the
  # stale ones stay subscribed. Swap them for instances of the reloaded classes.
  # Assumes subscribers use the default notifier, as all of ours do.
  module ReloadableSubscribers
    class << self
      def detach(loader = Rails.autoloaders.main)
        reloadable = loader.unloadable_cpaths.to_set
        stale = ActiveSupport::Subscriber.subscribers.select { |s| reloadable.include?(s.class.name) }

        stale.each do |subscriber|
          subscriber.patterns.each_value { |handle| ActiveSupport::Notifications.unsubscribe(handle) }
          ActiveSupport::Subscriber.subscribers.delete(subscriber)
        end

        stale.map { |subscriber| subscriber.class.name }.uniq
      end

      def reattach(names)
        names.each do |name|
          name.safe_constantize
        # A file being edited must not abort the other to_prepare callbacks;
        # the class still attaches when it's next referenced.
        rescue StandardError, SyntaxError => e
          Gitlab::ErrorTracking.track_exception(e, subscriber: name)
        end
      end
    end
  end
end
