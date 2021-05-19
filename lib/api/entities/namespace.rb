# frozen_string_literal: true

module API
  module Entities
    class Namespace < Entities::NamespaceBasic
      expose :members_count_with_descendants, if: -> (namespace, opts) { expose_members_count_with_descendants?(namespace, opts) } do |namespace, _|
        namespace.users_with_descendants.count
      end

      def expose_members_count_with_descendants?(namespace, opts)
        namespace.kind == 'group' && Ability.allowed?(opts[:current_user], :admin_group, namespace)
      end
    end
  end
end

API::Entities::Namespace.prepend_mod_with('API::Entities::Namespace')
