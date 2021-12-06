# frozen_string_literal: true

# Returns and caches in thread max member access for a resource
#
module BulkMemberAccessLoad
  extend ActiveSupport::Concern

  included do
    # Determine the maximum access level for a group of resources in bulk.
    #
    # Returns a Hash mapping resource ID -> maximum access level.
    def max_member_access_for_resource_ids(resource_klass, resource_ids, &block)
      raise 'Block is mandatory' unless block_given?

      memoization_index = self.id
      memoization_class = self.class

      resource_ids = resource_ids.uniq
      memo_id = "#{memoization_class}:#{memoization_index}"
      access = load_access_hash(resource_klass, memo_id)

      # Look up only the IDs we need
      resource_ids -= access.keys

      return access if resource_ids.empty?

      resource_access = yield(resource_ids)

      access.merge!(resource_access)

      missing_resource_ids = resource_ids - resource_access.keys

      missing_resource_ids.each do |resource_id|
        access[resource_id] = Gitlab::Access::NO_ACCESS
      end

      access
    end

    def merge_value_to_request_store(resource_klass, resource_id, value)
      max_member_access_for_resource_ids(resource_klass, [resource_id]) do
        { resource_id => value }
      end
    end

    private

    def max_member_access_for_resource_key(klass, memoization_index)
      "max_member_access_for_#{klass.name.underscore.pluralize}:#{memoization_index}"
    end

    def load_access_hash(resource_klass, memo_id)
      return {} unless Gitlab::SafeRequestStore.active?

      key = max_member_access_for_resource_key(resource_klass, memo_id)
      Gitlab::SafeRequestStore[key] ||= {}

      Gitlab::SafeRequestStore[key]
    end
  end
end
