# frozen_string_literal: true

module Packages
  class CreateEventService < BaseService
    def execute
      return unless Feature.enabled?(:collect_package_events, default_enabled: false)

      event_scope = scope.is_a?(::Packages::Package) ? scope.package_type : scope

      ::Packages::Event.create!(
        event_type: event_name,
        originator: current_user&.id,
        originator_type: originator_type,
        event_scope: event_scope
      )
    end

    private

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
  end
end
