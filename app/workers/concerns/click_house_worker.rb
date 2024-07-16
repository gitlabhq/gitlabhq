# frozen_string_literal: true

module ClickHouseWorker
  extend ActiveSupport::Concern

  class_methods do
    def register_click_house_worker?
      click_house_worker_attrs.present?
    end

    def click_house_worker_attrs
      get_class_attribute(:click_house_worker_attrs)
    end

    def click_house_migration_lock(ttl)
      raise ArgumentError unless ttl.is_a?(ActiveSupport::Duration)

      set_class_attribute(
        :click_house_worker_attrs,
        (click_house_worker_attrs || {}).merge(migration_lock_ttl: ttl)
      )
    end
  end

  included do
    click_house_migration_lock(ClickHouse::MigrationSupport::ExclusiveLock::DEFAULT_CLICKHOUSE_WORKER_TTL)

    worker_has_external_dependencies! # the worker interacts with a ClickHouse database
    pause_control :click_house_migration
  end
end
