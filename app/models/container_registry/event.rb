# frozen_string_literal: true

module ContainerRegistry
  class Event
    include Gitlab::Utils::StrongMemoize

    ALLOWED_ACTIONS = %w(push delete).freeze
    PUSH_ACTION = 'push'
    DELETE_ACTION = 'delete'
    EVENT_TRACKING_CATEGORY = 'container_registry:notification'
    EVENT_PREFIX = 'i_container_registry'

    ALLOWED_ACTOR_TYPES = %w(
      personal_access_token
      build
      gitlab_or_ldap
    ).freeze

    TRACKABLE_ACTOR_EVENTS = %w(
      push_tag
      delete_tag
      push_repository
      delete_repository
      create_repository
    ).freeze

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

      if manifest_delete_event?
        ::Gitlab::UsageDataCounters::ContainerRegistryEventCounter.count("#{EVENT_PREFIX}_delete_manifest")
      else
        event = usage_data_event_for(tracking_action)
        ::Gitlab::UsageDataCounters::HLLRedisCounter.track_event(event, values: originator.id) if event
      end
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

    # counter name for unique user tracking (for MAU)
    def usage_data_event_for(tracking_action)
      return unless originator
      return unless TRACKABLE_ACTOR_EVENTS.include?(tracking_action)

      "#{EVENT_PREFIX}_#{tracking_action}_user"
    end

    def originator_type
      event.dig('actor', 'user_type')
    end

    def originator
      return unless ALLOWED_ACTOR_TYPES.include?(originator_type)

      username = event.dig('actor', 'name')
      return unless username

      strong_memoize(:originator) do
        User.find_by_username(username)
      end
    end

    def manifest_delete_event?
      action_delete? && target_digest?
    end

    def update_project_statistics
      return unless supported?
      return unless target_tag? || manifest_delete_event?
      return unless project

      Rails.cache.delete(project.root_ancestor.container_repositories_size_cache_key)
      ProjectCacheWorker.perform_async(project.id, [], [:container_registry_size])
    end
  end
end

::ContainerRegistry::Event.prepend_mod_with('ContainerRegistry::Event')
