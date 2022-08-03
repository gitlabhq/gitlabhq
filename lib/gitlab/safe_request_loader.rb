# frozen_string_literal: true

module Gitlab
  class SafeRequestLoader
    def self.execute(args, &block)
      new(**args).execute(&block)
    end

    def initialize(resource_key:, resource_ids:, default_value: nil)
      @resource_key = resource_key
      @resource_ids = resource_ids.uniq
      @default_value = default_value
      @resource_data = {}
    end

    def execute(&block)
      raise ArgumentError, 'Block is mandatory' unless block

      load_resource_data
      remove_loaded_resource_ids

      update_resource_data(&block)

      resource_data
    end

    private

    attr_reader :resource_key, :resource_ids, :default_value, :resource_data, :missing_resource_ids

    def load_resource_data
      @resource_data = Gitlab::SafeRequestStore.fetch(resource_key) { resource_data }
    end

    def remove_loaded_resource_ids
      # Look up only the IDs we need
      @missing_resource_ids = resource_ids - resource_data.keys
    end

    def update_resource_data(&block)
      return if missing_resource_ids.blank?

      reloaded_resource_data = yield(missing_resource_ids)

      @resource_data.merge!(reloaded_resource_data)

      mark_absent_values
    end

    def mark_absent_values
      absent = (missing_resource_ids - resource_data.keys).to_h { [_1, default_value] }
      @resource_data.merge!(absent)
    end
  end
end
