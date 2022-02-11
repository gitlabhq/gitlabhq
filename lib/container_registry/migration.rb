# frozen_string_literal: true

module ContainerRegistry
  module Migration
    class << self
      delegate :container_registry_import_max_tags_count, to: ::Gitlab::CurrentSettings
      delegate :container_registry_import_max_retries, to: ::Gitlab::CurrentSettings
      delegate :container_registry_import_start_max_retries, to: ::Gitlab::CurrentSettings
      delegate :container_registry_import_max_step_duration, to: ::Gitlab::CurrentSettings
      delegate :container_registry_import_target_plan, to: ::Gitlab::CurrentSettings
      delegate :container_registry_import_created_before, to: ::Gitlab::CurrentSettings

      alias_method :max_tags_count, :container_registry_import_max_tags_count
      alias_method :max_retries, :container_registry_import_max_retries
      alias_method :start_max_retries, :container_registry_import_start_max_retries
      alias_method :max_step_duration, :container_registry_import_max_step_duration
      alias_method :target_plan_name, :container_registry_import_target_plan
      alias_method :created_before, :container_registry_import_created_before
    end

    def self.enabled?
      Feature.enabled?(:container_registry_migration_phase2_enabled)
    end

    def self.limit_gitlab_org?
      Feature.enabled?(:container_registry_migration_limit_gitlab_org)
    end

    def self.enqueue_waiting_time
      return 0 if Feature.enabled?(:container_registry_migration_phase2_enqueue_speed_fast)
      return 6.hours if Feature.enabled?(:container_registry_migration_phase2_enqueue_speed_slow)

      1.hour
    end

    def self.capacity
      return 25 if Feature.enabled?(:container_registry_migration_phase2_capacity_25)
      return 10 if Feature.enabled?(:container_registry_migration_phase2_capacity_10)
      return 1 if Feature.enabled?(:container_registry_migration_phase2_capacity_1)

      0
    end

    def self.target_plan
      Plan.find_by_name(target_plan_name)
    end
  end
end
