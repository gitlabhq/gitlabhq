# Returns and caches in thread max member access for a resource
#
module BulkMemberAccessLoad
  extend ActiveSupport::Concern

  included do
    # Determine the maximum access level for a group of resources in bulk.
    #
    # Returns a Hash mapping resource ID -> maximum access level.
    def max_member_access_for_resource_ids(resource_klass, resource_ids, memoization_index = self.id, &block)
      raise 'Block is mandatory' unless block_given?

      resource_ids = resource_ids.uniq
      key = max_member_access_for_resource_key(resource_klass, memoization_index)
      access = {}

      if RequestStore.active?
        RequestStore.store[key] ||= {}
        access = RequestStore.store[key]
      end

      # Look up only the IDs we need
      resource_ids = resource_ids - access.keys

      return access if resource_ids.empty?

      resource_access = yield(resource_ids)

      access.merge!(resource_access)

      missing_resource_ids = resource_ids - resource_access.keys

      missing_resource_ids.each do |resource_id|
        access[resource_id] = Gitlab::Access::NO_ACCESS
      end

      access
    end

    private

    def max_member_access_for_resource_key(klass, memoization_index)
      "max_member_access_for_#{klass.name.underscore.pluralize}:#{memoization_index}"
    end
  end
end
