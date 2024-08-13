# frozen_string_literal: true

module Packages
  class CreateEventService < BaseService
    INTERNAL_EVENTS_NAMES = {
      'delete_package' => 'delete_package_from_registry',
      'pull_package' => 'pull_package_from_registry',
      'push_package' => 'push_package_to_registry',
      'push_symbol_package' => 'push_symbol_package_to_registry',
      'pull_symbol_package' => 'pull_symbol_package_from_registry'
    }.freeze

    def execute
      ::Packages::Event.unique_counters_for(event_scope, event_name, originator_type).each do |event_name|
        ::Gitlab::UsageDataCounters::HLLRedisCounter.track_event(event_name, values: current_user.id)
      end

      return unless INTERNAL_EVENTS_NAMES.key?(event_name)

      user = current_user if current_user.is_a?(User)

      Gitlab::InternalEvents.track_event(
        INTERNAL_EVENTS_NAMES[event_name],
        user: user,
        project: project,
        namespace: params[:namespace],
        additional_properties: {
          label: event_scope.to_s,
          property: originator_type.to_s
        }
      )
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
  end
end
