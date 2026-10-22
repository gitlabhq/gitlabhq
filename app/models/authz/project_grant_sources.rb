# frozen_string_literal: true

module Authz
  # Loads the project data that decides who can access a project, whoever the user is: each project's
  # namespace, its project shares, and the group shares into the groups involved.
  # Cached for the request, so every user and preloader checking the same projects reuses it.
  class ProjectGrantSources
    include Gitlab::Utils::StrongMemoize

    GROUP_SHARE_KEYS = %i[shared_with_group_id group_access member_role_id].freeze
    PROJECT_SHARE_KEYS = %i[group_access member_role_id group_traversal_ids].freeze

    # @param projects [Array<Project, Integer>, ActiveRecord::Relation] projects, or their IDs
    # @return [Hash{Integer => Hash}] namespace type, owner, traversal IDs and share lock per existing project.
    #   A namespace already loaded on a project record is used without querying.
    def project_rows(projects)
      if relation?(projects)
        return queried_project_rows(projects.reselect(:id)).tap do |rows|
          project_row_cache.merge!(rows)
        end
      end

      loaded, unloaded = Array(projects).partition { |project| project.is_a?(::Project) && loaded_namespace(project) }
      rows = loaded.select(&:persisted?).to_h { |project| [project.id, namespace_row(loaded_namespace(project))] }

      ids = unloaded.filter_map { |project| project.is_a?(::Project) ? project.id : project }
      fill(project_row_cache, ids) { |missing| queried_project_rows(missing) }

      rows.merge(project_row_cache.slice(*ids).compact)
    end

    # @param project_ids [Array<Integer>]
    # @return [Hash{Integer => Array<Hash>}] each project's shares, with the invited group's traversal IDs
    def project_shares(project_ids)
      fill(project_share_cache, project_ids) { |missing| queried_project_shares(missing) }

      project_share_cache.slice(*project_ids)
    end

    # Groups whose memberships can grant access to the projects: each project's own hierarchy, and the
    # hierarchy of each group invited to them.
    #
    # @return [Array<Integer>]
    def hierarchy_group_ids(rows, project_shares)
      group_ids = rows.values.select { |project| project[:namespace_type] == ::Group.sti_name }
        .flat_map { |project| project[:traversal_ids] }

      (group_ids + project_shares.values.flatten.flat_map { |share| share[:group_traversal_ids] }).uniq
    end

    # Group shares into the given groups. Shares at or below Minimal Access are kept for their custom roles.
    #
    # @param group_ids [Array<Integer>]
    # @return [Hash{Integer => Array<Hash>}] keyed by the shared group
    def group_shares(group_ids)
      fill(group_share_cache, group_ids) { |missing| queried_group_shares(missing) }

      group_share_cache.slice(*group_ids)
    end

    # Shares into one group, loaded with #group_shares when not loaded yet.
    #
    # @param group_id [Integer]
    # @return [Array<Hash>]
    def shares_into(group_id)
      group_share_cache.fetch(group_id) { group_shares([group_id]).fetch(group_id) }
    end

    private

    # Queries the IDs missing from the cache and records every one of them, so IDs that don't exist are not
    # queried again. Checking keys one by one keeps repeated calls in a request linear.
    def fill(cache, ids)
      missing = ids.reject { |id| cache.key?(id) }
      return if missing.empty?

      found = yield(missing)
      missing.each { |id| cache[id] = found[id] }
    end

    def project_row_cache
      request_cache(:authz_project_grant_sources_project_rows)
    end
    strong_memoize_attr :project_row_cache

    def project_share_cache
      request_cache(:authz_project_grant_sources_project_shares)
    end
    strong_memoize_attr :project_share_cache

    def group_share_cache
      request_cache(:authz_project_grant_sources_group_shares)
    end
    strong_memoize_attr :group_share_cache

    def request_cache(key)
      Gitlab::SafeRequestStore.fetch(key) { {} }
    end

    def relation?(projects)
      projects.is_a?(ActiveRecord::Relation)
    end

    # A loaded group is the project's namespace, and reading it avoids loading the namespace association.
    def loaded_namespace(project)
      return project.group if project.association(:group).loaded? && project.group
      return project.namespace if project.association(:namespace).loaded?

      nil
    end

    def namespace_row(namespace)
      {
        namespace_type: namespace.type,
        owner_id: namespace.owner_id,
        traversal_ids: namespace.traversal_ids,
        share_with_group_lock: namespace.share_with_group_lock
      }
    end

    def queried_project_rows(projects)
      namespaces = ::Namespace.arel_table
      columns = [:id, namespaces[:type], namespaces[:owner_id], namespaces[:traversal_ids],
        namespaces[:share_with_group_lock]]

      ::Project.id_in(projects).joins(:namespace)
        .pluck(*columns) # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- bounded by the projects being checked
        .to_h do |id, namespace_type, owner_id, traversal_ids, share_with_group_lock|
          [id, {
            namespace_type: namespace_type,
            owner_id: owner_id,
            traversal_ids: traversal_ids,
            share_with_group_lock: share_with_group_lock
          }]
        end
    end

    # Every project gets an entry, so projects without shares are not queried again.
    def queried_project_shares(project_ids)
      shares = project_ids.index_with { [] }

      ::ProjectGroupLink.where(project_id: project_ids).joins(:group)
        .pluck(:project_id, :group_access, :member_role_id, ::Namespace.arel_table[:traversal_ids]) # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- bounded by the projects being checked
        .each { |project_id, *share| shares[project_id] << PROJECT_SHARE_KEYS.zip(share).to_h }

      shares
    end

    # Joining an unnested array keeps planning flat; an IN list of 100k IDs took over a second to plan.
    def queried_group_shares(group_ids)
      shares = group_ids.index_with { [] }
      shared_groups_join = ::GroupGroupLink.sanitize_sql_array([
        'INNER JOIN unnest(?::bigint[]) AS shared_groups(id) ON shared_groups.id = group_group_links.shared_group_id',
        "{#{group_ids.map { |id| Integer(id) }.join(',')}}"
      ])

      ::GroupGroupLink.joins(shared_groups_join)
        .pluck(:shared_group_id, :shared_with_group_id, :group_access, :member_role_id) # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- bounded by the groups being checked
        .each { |shared_group_id, *share| shares[shared_group_id] << GROUP_SHARE_KEYS.zip(share).to_h }

      shares
    end
  end
end
