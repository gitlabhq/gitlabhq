# frozen_string_literal: true

module Gitlab
  module RackAttack
    # This class is a proxy for all Redis calls made by RackAttack. All the
    # calls are instrumented, then redirected to ::Rails.cache. This class
    # instruments the standard interfaces of ActiveRecord::Cache defined in
    # https://github.com/rails/rails/blob/v6.0.3.1/activesupport/lib/active_support/cache.rb#L315
    #
    # For more information, please see
    # https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/751
    class InstrumentedCacheStore
      NOTIFICATION_CHANNEL = 'redis.rack_attack'

      delegate :silence!, :mute, to: :@upstream_store

      def initialize(upstream_store: ::Rails.cache, notifier: ActiveSupport::Notifications)
        @upstream_store = upstream_store
        @notifier = notifier
      end

      [:fetch, :read, :read_multi, :write_multi, :fetch_multi, :write, :delete,
       :exist?, :delete_matched, :increment, :decrement, :cleanup, :clear].each do |interface|
        define_method interface do |*args, **k_args, &block|
          @notifier.instrument(NOTIFICATION_CHANNEL, operation: interface) do
            @upstream_store.public_send(interface, *args, **k_args, &block) # rubocop:disable GitlabSecurity/PublicSend
          end
        end
      end
    end
  end
end
