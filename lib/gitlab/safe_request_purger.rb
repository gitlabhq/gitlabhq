# frozen_string_literal: true

module Gitlab
  class SafeRequestPurger
    def self.execute(args)
      new(**args).execute
    end

    def initialize(resource_key:, resource_ids:)
      @resource_key = resource_key
      @resource_ids = resource_ids.uniq
      @resource_data = {}
    end

    def execute
      load_resource_data
      purge_resource_ids
      write_resource_data_to_store
    end

    private

    attr_reader :resource_key, :resource_ids, :resource_data

    def load_resource_data
      @resource_data = Gitlab::SafeRequestStore.fetch(resource_key) { resource_data }
    end

    def purge_resource_ids
      @resource_data.delete_if { |id| resource_ids.include?(id) }
    end

    def write_resource_data_to_store
      Gitlab::SafeRequestStore.write(resource_key, resource_data)
    end
  end
end
