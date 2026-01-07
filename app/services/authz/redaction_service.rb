# frozen_string_literal: true

module Authz
  # Service to perform batch authorization checks for resources.
  #
  # This service is designed to check whether a user has read access to a batch
  # of resources using GitLab's standard Ability system. It's used by the
  # Knowledge Graph service for final redaction but is generic enough
  # to be used by any service requiring batch authorization checks.
  #
  # IMPORTANT: This service assumes that the user has already been authenticated
  # and authorized to make API requests. It does NOT perform user-level validation
  # (e.g., checking if user is blocked or deactivated). The caller is responsible
  # for ensuring the user is valid before invoking this service.
  #
  # @example
  #   service = Authz::RedactionService.new(
  #     user: current_user,
  #     resources_by_type: {
  #       'issues' => [123, 456],
  #       'merge_requests' => [789]
  #     },
  #     source: 'knowledge_graph'
  #   )
  #   result = service.execute
  #   # => {
  #   #      'issues' => { 123 => true, 456 => false },
  #   #      'merge_requests' => { 789 => true }
  #   #    }
  class RedactionService
    include Gitlab::Allowable

    RESOURCE_CLASSES = {
      'issues' => ::Issue,
      'merge_requests' => ::MergeRequest,
      'projects' => ::Project,
      'milestones' => ::Milestone,
      'snippets' => ::Snippet
    }.freeze

    PRELOAD_ASSOCIATIONS = {
      'issues' => [{ project: [:namespace, :project_feature, :group] }, :author, :work_item_type],
      'merge_requests' => [{ target_project: [:namespace, :project_feature, :group] }, :author],
      'projects' => [:namespace, :project_feature, :group],
      'milestones' => [{ project: [:namespace, :project_feature] }, :group],
      'snippets' => [{ project: [:namespace, :project_feature] }, :author]
    }.freeze

    def self.supported_types
      RESOURCE_CLASSES.keys
    end

    def initialize(user:, resources_by_type:, source:, logger: nil)
      raise ArgumentError, 'user is required' if user.nil?

      @user = user
      @resources_by_type = resources_by_type
      @source = source
      @logger = logger
    end

    def execute
      return {} if resources_by_type.empty?

      loaded_resources_by_type = load_all_resources

      results = DeclarativePolicy.user_scope do
        resources_by_type.each_with_object({}) do |(type, ids), authorization_results|
          authorization_results[type] = authorize_resources_of_type(type, ids, loaded_resources_by_type[type] || {})
        end
      end

      log_redacted_results(results)

      results
    end

    private

    attr_reader :user, :resources_by_type, :source, :logger

    def load_all_resources
      resources_by_type.each_with_object({}) do |(type, ids), loaded|
        loaded[type] = load_resources_for_type(type, ids)
      end
    end

    # rubocop:disable CodeReuse/ActiveRecord -- Batch loading with preloads for authorization checks
    def load_resources_for_type(type, ids)
      return {} if ids.blank?

      klass = RESOURCE_CLASSES[type]
      return {} unless klass

      preloads = PRELOAD_ASSOCIATIONS[type]
      relation = klass.where(id: ids)
      relation = relation.includes(*preloads) if preloads
      relation.index_by(&:id)
    end
    # rubocop:enable CodeReuse/ActiveRecord

    def authorize_resources_of_type(type, ids, loaded_resources)
      return {} if ids.blank?

      klass = RESOURCE_CLASSES[type]
      return ids.index_with { false } unless klass

      ids.index_with do |id|
        resource = loaded_resources[id]

        next false if resource.nil?

        visible_result?(resource)
      end
    end

    def visible_result?(resource)
      return false unless resource.respond_to?(:to_ability_name) && DeclarativePolicy.has_policy?(resource)

      Ability.allowed?(user, :"read_#{resource.to_ability_name}", resource)
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
