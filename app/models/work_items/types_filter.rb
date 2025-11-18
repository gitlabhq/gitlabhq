# frozen_string_literal: true

module WorkItems
  class TypesFilter
    include ::Gitlab::Utils::StrongMemoize

    OKR_TYPES = %w[key_result objective].freeze
    DISABLED_WORKFLOW_TYPES = %w[requirement test_case].freeze

    def self.allowed?(container:, type:)
      new(container: container)
        .allowed_types
        .include?(type)
    end

    def self.allowed_types_for_issues
      base_types.keys.excluding('epic', *OKR_TYPES)
    end

    def self.base_types
      ::WorkItems::Type.base_types
    end

    def initialize(container:)
      @container = container
    end

    # Filter types by the given resource_parent. The filters take in consideration
    # - resource_parent type
    # - enabled/disabled workflows
    # - feature flags
    #
    # PS.: the order the filters are applied matters
    def allowed_types
      return [] if resource_parent.blank?

      base_types.keys.to_set
        .then { |types| filter_resource_parent_type(types) }
        .then { |types| filter_disabled_workflows(types) }
        .then { |types| filter_service_desk(types) }
        .then { |types| filter_epic(types) } # overridden in EE
        .then { |types| filter_okr(types) } # overridden in EE
    end

    private

    def base_types
      self.class.base_types
    end

    def resource_parent
      return if @container.owner_entity_name == :user

      @container.owner_entity
    end
    strong_memoize_attr :resource_parent

    def filter_resource_parent_type(types)
      return types if project_resource_parent?

      types.clear
    end

    # These types are not enabled in the UI yet.
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/183399#note_2394091541
    def filter_disabled_workflows(types)
      types.subtract(DISABLED_WORKFLOW_TYPES)
    end

    def filter_service_desk(types)
      return types if Feature.enabled?(:service_desk_ticket) # rubocop:disable Gitlab/FeatureFlagWithoutActor -- legacy feature flag

      types.subtract(%w[ticket])
    end

    # overridden in EE: epic is not available on FOSS
    def filter_epic(types)
      types.subtract(%w[epic])
    end

    # overridden in EE: OKR types are not available on FOSS
    def filter_okr(types)
      types.subtract(OKR_TYPES)
    end

    def project_resource_parent?
      resource_parent.is_a?(::Project)
    end
  end
end

WorkItems::TypesFilter.prepend_mod
