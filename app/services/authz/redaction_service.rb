# frozen_string_literal: true

module Authz
  # Service to perform batch authorization checks for resources.
  #
  # This service is designed to check whether a user has access to a batch
  # of resources using GitLab's standard Ability system. It's used by the
  # Knowledge Graph service for final redaction but is generic enough
  # to be used by any service requiring batch authorization checks.
  #
  # IMPORTANT: This service assumes that the user has already been authenticated
  # and authorized to make API requests. It does NOT perform user-level validation
  # (e.g., checking if user is blocked or deactivated). The caller is responsible
  # for ensuring the user is valid before invoking this service.
  #
  # The caller always passes in the ability name for each resource type.
  # If no ability is provided, access is denied (fail-closed).
  #
  # @example
  #   service = Authz::RedactionService.new(
  #     user: current_user,
  #     resources_by_type: {
  #       'project' => {
  #         'ids' => [123, 456],
  #         'ability' => 'read_project'
  #       },
  #       'merge_request' => {
  #         'ids' => [789],
  #         'ability' => 'read_merge_request'
  #       }
  #     },
  #     source: 'knowledge_graph'
  #   )
  #   result = service.execute
  #   # => {
  #   #      'project' => { 123 => true, 456 => false },
  #   #      'merge_request' => { 789 => true }
  #   #    }
  class RedactionService
    include Gitlab::Allowable

    RESOURCE_CLASSES = {
      issue: ::Issue,
      merge_request: ::MergeRequest,
      project: ::Project,
      milestone: ::Milestone,
      snippet: ::Snippet,
      user: ::User,
      group: ::Group,
      work_item: ::WorkItem
    }.freeze

    PRELOAD_ASSOCIATIONS = {
      issue: [:namespace, :assignees, { project: [:namespace, :project_feature, :group, :organization] }, :author],
      merge_request: [{ target_project: [:namespace, :project_feature, :group, :organization] }, :author],
      project: [:namespace, :project_feature, :group, :organization],
      milestone: [{ project: [:namespace, :project_feature, :group, :organization] }, :group],
      snippet: [{ project: [:namespace, :project_feature] }, :author],
      user: [],
      group: [:parent, :organization],
      work_item: [:namespace, :assignees, :author,
        { project: [:namespace, :project_feature, :group, :organization] }]
    }.freeze

    def self.supported_types
      RESOURCE_CLASSES.keys.map(&:to_s)
    end

    def initialize(user:, resources_by_type:, source:, logger: nil, metrics_observer: nil)
      raise ArgumentError, 'user is required' if user.nil?

      @user = user
      @resources_by_type = resources_by_type
      @source = source
      @logger = logger
      @metrics_observer = metrics_observer
    end

    def execute
      return {} if resources_by_type.empty?

      start = ::Gitlab::Metrics::System.monotonic_time

      loaded_resources_by_type = load_all_resources
      preseed_authorization_caches(loaded_resources_by_type)

      results = DeclarativePolicy.user_scope do
        resources_by_type.each_with_object({}) do |(type, config), authorization_results|
          type_sym = type.to_sym
          config_sym = config.symbolize_keys
          ids = config_sym[:ids]
          ability = config_sym[:ability]
          authorization_results[type] =
            authorize_resources_of_type(type_sym, ids, ability, loaded_resources_by_type[type_sym] || {})
        end
      end

      duration = ::Gitlab::Metrics::System.monotonic_time - start
      observe_redaction_metrics(results, duration)

      results
    end

    private

    attr_reader :user, :resources_by_type, :source, :logger, :metrics_observer

    def preseed_authorization_caches(loaded_resources_by_type)
      projects, groups = collect_policy_subjects(loaded_resources_by_type)

      ::Preloaders::ProjectPolicyPreloader.new(projects, user).execute if projects.any?
      ::Preloaders::GroupPolicyPreloader.new(groups, user).execute if groups.any?
    end

    def collect_policy_subjects(loaded_resources_by_type)
      projects = []
      groups = []

      loaded_resources_by_type.each do |type, resources|
        resources.each_value do |resource|
          case type
          when :project then projects << resource
          when :merge_request then projects << resource.target_project if resource.target_project.is_a?(::Project)
          when :group then groups << resource
          else
            projects << resource.project if resource.respond_to?(:project) && resource.project.is_a?(::Project)
            groups << resource.group if resource.respond_to?(:group) && resource.group.is_a?(::Group)
          end
        end
      end

      projects.uniq!(&:id)
      projects.each { |p| groups << p.group if p.group.is_a?(::Group) }
      groups.uniq!(&:id)

      [projects, groups]
    end

    def load_all_resources
      resources_by_type.each_with_object({}) do |(type, config), loaded|
        type_sym = type.to_sym
        config_sym = config.symbolize_keys
        loaded[type_sym] = load_resources_for_type(type_sym, config_sym[:ids])
      end
    end

    # rubocop:disable CodeReuse/ActiveRecord -- Batch loading with preloads for authorization checks
    def load_resources_for_type(type, ids)
      return {} if ids.blank?

      klass = RESOURCE_CLASSES[type]
      return {} unless klass

      preloads = PRELOAD_ASSOCIATIONS[type]
      relation = klass.where(id: ids)
      relation = relation.includes(*preloads) if preloads.present?
      relation.index_by(&:id)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    def authorize_resources_of_type(type, ids, ability, loaded_resources)
      return {} if ids.blank?

      klass = RESOURCE_CLASSES[type]
      return ids.index_with { false } unless klass

      ids.index_with do |id|
        resource = loaded_resources[id]

        next false if resource.nil?

        check_ability(resource, ability)
      end
    end

    def check_ability(resource, ability)
      return false if ability.blank?
      return false unless DeclarativePolicy.has_policy?(resource)

      Ability.allowed?(user, ability.to_sym, resource)
    end

    def observe_redaction_metrics(results, duration)
      if metrics_observer
        total = results.values.sum(&:size)
        filtered = results.values.sum { |r| r.count { |_, v| !v } }
        metrics_observer.call(total: total, filtered: filtered, duration: duration)
      end

      log_redacted_results(results)
    end

    def log_redacted_results(results)
      return unless logger

      redacted_by_type = results.transform_values do |id_results|
        id_results.count { |_id, authorized| !authorized }
      end

      total_redacted = redacted_by_type.values.sum
      return if total_redacted == 0

      log_info = {
        class: self.class.name,
        message: 'redacted_authorization_results',
        source: source,
        user_id: user.id,
        total_requested: results.values.sum(&:size),
        total_redacted: total_redacted,
        redacted_by_type: redacted_by_type
      }

      logger.error(log_info)
    end
  end
end

Authz::RedactionService.prepend_mod_with('Authz::RedactionService')
