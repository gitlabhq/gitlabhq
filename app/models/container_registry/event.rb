# frozen_string_literal: true

module ContainerRegistry
  class Event
    include Gitlab::Utils::StrongMemoize

    ALLOWED_ACTIONS = %w(push delete).freeze
    PUSH_ACTION = 'push'
    DELETE_ACTION = 'delete'
    EVENT_TRACKING_CATEGORY = 'container_registry:notification'

    attr_reader :event

    def initialize(event)
      @event = event
    end

    def supported?
      action.in?(ALLOWED_ACTIONS)
    end

    def handle!
      update_project_statistics
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

    def target_digest?
      event['target'].has_key?('digest')
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

    def action_delete?
      DELETE_ACTION == action
    end

    def container_repository_exists?
      return unless container_registry_path

      ContainerRepository.exists_by_path?(container_registry_path)
    end

    def container_registry_path
      strong_memoize(:container_registry_path) do
        path = event.dig('target', 'repository')
        next unless path

        ContainerRegistry::Path.new(path)
      end
    end

    def project
      container_registry_path&.repository_project
    end

    def update_project_statistics
      return unless supported?
      return unless target_tag? || (action_delete? && target_digest?)
      return unless project

      Rails.cache.delete(project.root_ancestor.container_repositories_size_cache_key)
      ProjectCacheWorker.perform_async(project.id, [], [:container_registry_size])
    end
  end
end

::ContainerRegistry::Event.prepend_mod_with('ContainerRegistry::Event')
