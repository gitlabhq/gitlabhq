# frozen_string_literal: true

module BulkMemberAccessLoad
  extend ActiveSupport::Concern

  included do
    def merge_value_to_request_store(resource_klass, resource_id, value)
      Gitlab::SafeRequestLoader.execute(
        resource_key: max_member_access_for_resource_key(resource_klass),
        resource_ids: [resource_id],
        default_value: Gitlab::Access::NO_ACCESS
      ) do
        { resource_id => value }
      end
    end

    def purge_resource_id_from_request_store(resource_klass, resource_id)
      Gitlab::SafeRequestPurger.execute(
        resource_key: max_member_access_for_resource_key(resource_klass),
        resource_ids: [resource_id]
      )
    end

    def max_member_access_for_resource_key(klass)
      "max_member_access_for_#{klass.name.underscore.pluralize}:#{self.class}:#{self.id}"
    end
  end
end
