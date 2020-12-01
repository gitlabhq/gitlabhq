# frozen_string_literal: true

module Packages
  class CreateEventService < BaseService
    def execute
      if Feature.enabled?(:collect_package_events_redis) && redis_event_name
        unless guest?
          ::Gitlab::UsageDataCounters::HLLRedisCounter.track_event(current_user.id, redis_event_name)
        end
      end

      if Feature.enabled?(:collect_package_events) && Gitlab::Database.read_write?
        ::Packages::Event.create!(
          event_type: event_name,
          originator: current_user&.id,
          originator_type: originator_type,
          event_scope: event_scope
        )
      end
    end

    private

    def redis_event_name
      @redis_event_name ||= ::Packages::Event.allowed_event_name(event_scope, event_name, originator_type)
    end

    def event_scope
      @event_scope ||= scope.is_a?(::Packages::Package) ? scope.package_type : scope
    end

    def scope
      params[:scope]
    end

    def event_name
      params[:event_name]
    end

    def originator_type
      case current_user
      when User
        :user
      when DeployToken
        :deploy_token
      else
        :guest
      end
    end

    def guest?
      originator_type == :guest
    end
  end
end
