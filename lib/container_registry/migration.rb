# frozen_string_literal: true

module ContainerRegistry
  module Migration
    # Some container repositories do not have a plan associated with them, they will be imported with
    # the free tiers
    FREE_TIERS = ['free', 'early_adopter', nil].freeze
    PREMIUM_TIERS = %w[premium bronze silver premium_trial].freeze
    ULTIMATE_TIERS = %w[ultimate gold ultimate_trial].freeze
    PLAN_GROUPS = {
      'free' => FREE_TIERS,
      'premium' => PREMIUM_TIERS,
      'ultimate' => ULTIMATE_TIERS
    }.freeze

    class << self
      delegate :container_registry_import_max_tags_count, to: ::Gitlab::CurrentSettings
      delegate :container_registry_import_max_retries, to: ::Gitlab::CurrentSettings
      delegate :container_registry_import_start_max_retries, to: ::Gitlab::CurrentSettings
      delegate :container_registry_import_max_step_duration, to: ::Gitlab::CurrentSettings
      delegate :container_registry_import_target_plan, to: ::Gitlab::CurrentSettings
      delegate :container_registry_import_created_before, to: ::Gitlab::CurrentSettings
      delegate :container_registry_pre_import_timeout, to: ::Gitlab::CurrentSettings
      delegate :container_registry_import_timeout, to: ::Gitlab::CurrentSettings
      delegate :container_registry_pre_import_tags_rate, to: ::Gitlab::CurrentSettings

      alias_method :max_tags_count, :container_registry_import_max_tags_count
      alias_method :max_retries, :container_registry_import_max_retries
      alias_method :start_max_retries, :container_registry_import_start_max_retries
      alias_method :max_step_duration, :container_registry_import_max_step_duration
      alias_method :target_plan_name, :container_registry_import_target_plan
      alias_method :created_before, :container_registry_import_created_before
      alias_method :pre_import_timeout, :container_registry_pre_import_timeout
      alias_method :import_timeout, :container_registry_import_timeout
      alias_method :pre_import_tags_rate, :container_registry_pre_import_tags_rate
    end

    def self.enabled?
      Feature.enabled?(:container_registry_migration_phase2_enabled)
    end

    def self.limit_gitlab_org?
      Feature.enabled?(:container_registry_migration_limit_gitlab_org)
    end

    def self.delete_container_repository_worker_support?
      Feature.enabled?(:container_registry_migration_phase2_delete_container_repository_worker_support)
    end

    def self.enqueue_waiting_time
      return 0 if Feature.enabled?(:container_registry_migration_phase2_enqueue_speed_fast)
      return 165.minutes if Feature.enabled?(:container_registry_migration_phase2_enqueue_speed_slow)

      45.minutes
    end

    def self.capacity
      return 40 if Feature.enabled?(:container_registry_migration_phase2_capacity_40)
      return 25 if Feature.enabled?(:container_registry_migration_phase2_capacity_25)
      return 10 if Feature.enabled?(:container_registry_migration_phase2_capacity_10)
      return 5 if Feature.enabled?(:container_registry_migration_phase2_capacity_5)
      return 2 if Feature.enabled?(:container_registry_migration_phase2_capacity_2)
      return 1 if Feature.enabled?(:container_registry_migration_phase2_capacity_1)

      0
    end

    def self.target_plans
      PLAN_GROUPS[target_plan_name]
    end

    def self.all_plans?
      Feature.enabled?(:container_registry_migration_phase2_all_plans)
    end

    def self.dynamic_pre_import_timeout_for(repository)
      (repository.tags_count * pre_import_tags_rate).seconds
    end
  end
end
