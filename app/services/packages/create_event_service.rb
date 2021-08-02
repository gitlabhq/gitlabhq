# frozen_string_literal: true

module Packages
  class CreateEventService < BaseService
    def execute
      ::Packages::Event.unique_counters_for(event_scope, event_name, originator_type).each do |event_name|
        ::Gitlab::UsageDataCounters::HLLRedisCounter.track_event(event_name, values: current_user.id)
      end

      ::Packages::Event.counters_for(event_scope, event_name, originator_type).each do |event_name|
        ::Gitlab::UsageDataCounters::PackageEventCounter.count(event_name)
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
