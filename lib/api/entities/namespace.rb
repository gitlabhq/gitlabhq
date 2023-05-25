# frozen_string_literal: true

module API
  module Entities
    class Namespace < Entities::NamespaceBasic
      expose :members_count_with_descendants, documentation: { type: 'integer', example: 5 }, if: -> (namespace, opts) { expose_members_count_with_descendants?(namespace, opts) } do |namespace, _|
        namespace.users_with_descendants.count
      end

      def expose_members_count_with_descendants?(namespace, opts)
        namespace.kind == 'group' && Ability.allowed?(opts[:current_user], :admin_group, namespace)
      end

      expose :root_repository_size, documentation: { type: 'integer', example: 123 }, if: -> (namespace, opts) { expose_root_repository_size?(namespace, opts) } do |namespace, _|
        namespace.root_storage_statistics&.repository_size
      end

      def expose_root_repository_size?(namespace, opts)
        namespace.kind == 'group' && Ability.allowed?(opts[:current_user], :admin_group, namespace)
      end
    end
  end
end

API::Entities::Namespace.prepend_mod_with('API::Entities::Namespace')
