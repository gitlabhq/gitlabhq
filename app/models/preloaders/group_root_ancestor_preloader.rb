# frozen_string_literal: true

module Preloaders
  class GroupRootAncestorPreloader < NamespaceRootAncestorPreloader
    extend Gitlab::Utils::Override

    private

    override :join_sql
    def join_sql
      Group.select('id, traversal_ids[1] as root_id').where(id: @namespaces.map(&:id)).to_sql
    end
  end
end
