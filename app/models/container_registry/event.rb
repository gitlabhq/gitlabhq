# frozen_string_literal: true

module ContainerRegistry
  class Event
    ALLOWED_ACTIONS = %w(push delete).freeze
    PUSH_ACTION = 'push'
    EVENT_TRACKING_CATEGORY = 'container_registry:notification'

    attr_reader :event

    def initialize(event)
      @event = event
    end

    def supported?
      action.in?(ALLOWED_ACTIONS)
    end

    def handle!
      # no op
    end

    def track!
      tracked_target = target_tag? ? :tag : :repository
      tracking_action = "#{action}_#{tracked_target}"

      if target_repository? && action_push? && !container_repository_exists?
        tracking_action = "create_repository"
      end

      ::Gitlab::Tracking.event(EVENT_TRACKING_CATEGORY, tracking_action)
    end

    private

    def target_tag?
      # There is no clear indication in the event structure when we delete a top-level manifest
      # except existance of "tag" key
      event['target'].has_key?('tag')
    end

    def target_repository?
      !target_tag? && event['target'].has_key?('repository')
    end

    def action
      event['action']
    end

    def action_push?
      PUSH_ACTION == action
    end

    def container_repository_exists?
      return unless container_registry_path

      ContainerRepository.exists_by_path?(container_registry_path)
    end

    def container_registry_path
      path = event.dig('target', 'repository')
      return unless path

      ContainerRegistry::Path.new(path)
    end
  end
end

::ContainerRegistry::Event.prepend_mod_with('ContainerRegistry::Event')
