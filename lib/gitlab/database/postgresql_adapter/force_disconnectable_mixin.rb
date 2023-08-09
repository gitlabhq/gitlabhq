# frozen_string_literal: true

module Gitlab
  module Database
    module PostgresqlAdapter
      module ForceDisconnectableMixin
        extend ActiveSupport::Concern

        prepended do
          set_callback :checkin, :after, :force_disconnect_if_old!
        end

        def force_disconnect_if_old!
          return if Rails.env.test? && transaction_open?

          if force_disconnect_timer.expired?
            disconnect!
            reset_force_disconnect_timer!
          end
        end

        def reset_force_disconnect_timer!
          force_disconnect_timer.reset!
        end

        def force_disconnect_timer
          @force_disconnect_timer ||= ::Gitlab::Database::ConnectionTimer.starting_now
        end
      end
    end
  end
end
