# frozen_string_literal: true

module Namespaces
  module Traversal
    module Cached
      extend ActiveSupport::Concern
      extend Gitlab::Utils::Override

      included do
        after_destroy :invalidate_descendants_cache
      end

      private

      override :sync_traversal_ids
      def sync_traversal_ids
        super
        return if is_a?(Namespaces::UserNamespace)
        return unless Feature.enabled?(:namespace_descendants_cache_expiration, self, type: :gitlab_com_derisk)

        ids = [id]
        ids.concat((saved_changes[:parent_id] - [parent_id]).compact) if saved_changes[:parent_id]
        Namespaces::Descendants.expire_for(ids)
      end

      def invalidate_descendants_cache
        return if is_a?(Namespaces::UserNamespace)
        return unless Feature.enabled?(:namespace_descendants_cache_expiration, self, type: :gitlab_com_derisk)

        Namespaces::Descendants.expire_for([parent_id, id].compact)
      end
    end
  end
end
