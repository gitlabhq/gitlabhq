module Geo
  class ProjectRegistryFinder < RegistryFinder
    def count_repositories
      current_node.projects.count
    end

    def count_wikis
      current_node.projects.with_wiki_enabled.count
    end

    def count_synced_repositories
      relation =
        if selective_sync?
          legacy_find_synced_repositories
        else
          find_synced_repositories
        end

      relation.count
    end

    def count_synced_wikis
      relation =
        if use_legacy_queries?
          legacy_find_synced_wikis
        else
          fdw_find_synced_wikis
        end

      relation.count
    end

    def count_failed_repositories
      find_failed_project_registries('repository').count
    end

    def count_failed_wikis
      find_failed_project_registries('wiki').count
    end

    def find_failed_project_registries(type = nil)
      if selective_sync?
        legacy_find_filtered_failed_projects(type)
      else
        find_filtered_failed_project_registries(type)
      end
    end

    def count_verified_repositories
      relation =
        if use_legacy_queries?
          legacy_find_verified_repositories
        else
          find_verified_repositories
        end

      relation.count
    end

    def count_verified_wikis
      relation =
        if use_legacy_queries?
          legacy_find_verified_wikis
        else
          fdw_find_verified_wikis
        end

      relation.count
    end

    def count_repositories_checksum_mismatch
      Geo::ProjectRegistry.repository_checksum_mismatch.count
    end

    def count_wikis_checksum_mismatch
      Geo::ProjectRegistry.wiki_checksum_mismatch.count
    end

    def count_verification_failed_repositories
      find_verification_failed_project_registries('repository').count
    end

    def count_verification_failed_wikis
      find_verification_failed_project_registries('wiki').count
    end

    def find_verification_failed_project_registries(type = nil)
      if use_legacy_queries?
        legacy_find_filtered_verification_failed_projects(type)
      else
        find_filtered_verification_failed_project_registries(type)
      end
    end

    # Find all registries that need a repository or wiki verification
    def find_registries_to_verify(batch_size:)
      if use_legacy_queries?
        legacy_find_registries_to_verify(batch_size: batch_size)
      else
        fdw_find_registries_to_verify(batch_size: batch_size)
      end
    end

    def find_unsynced_projects(batch_size:)
      relation =
        if use_legacy_queries?
          legacy_find_unsynced_projects
        else
          fdw_find_unsynced_projects
        end

      relation.limit(batch_size)
    end

    def find_projects_updated_recently(batch_size:)
      relation =
        if use_legacy_queries?
          legacy_find_projects_updated_recently
        else
          fdw_find_projects_updated_recently
        end

      relation.limit(batch_size)
    end

    protected

    def find_synced_repositories
      Geo::ProjectRegistry.synced_repos
    end

    def find_verified_repositories
      Geo::ProjectRegistry.verified_repos
    end

    def find_filtered_failed_project_registries(type = nil)
      case type
      when 'repository'
        Geo::ProjectRegistry.failed_repos
      when 'wiki'
        Geo::ProjectRegistry.failed_wikis
      else
        Geo::ProjectRegistry.failed
      end
    end

    def find_filtered_verification_failed_project_registries(type = nil)
      case type
      when 'repository'
        Geo::ProjectRegistry.verification_failed_repos
      when 'wiki'
        Geo::ProjectRegistry.verification_failed_wikis
      else
        Geo::ProjectRegistry.verification_failed
      end
    end

    #
    # FDW accessors
    #

    # @return [ActiveRecord::Relation<Geo::Fdw::Project>]
    def fdw_find_unsynced_projects
      Geo::Fdw::Project.joins("LEFT OUTER JOIN project_registry ON project_registry.project_id = #{fdw_project_table}.id")
        .where(project_registry: { project_id: nil })
    end

    # @return [ActiveRecord::Relation<Geo::ProjectRegistry>]
    def fdw_find_synced_wikis
      Geo::ProjectRegistry.synced_wikis.where(fdw_enabled_wikis)
    end

    # @return [ActiveRecord::Relation<Geo::Fdw::Project>]
    def fdw_find_projects_updated_recently
      Geo::Fdw::Project.joins("INNER JOIN project_registry ON project_registry.project_id = #{fdw_project_table}.id")
          .merge(Geo::ProjectRegistry.dirty)
          .merge(Geo::ProjectRegistry.retry_due)
    end

    # Find all registries that repository or wiki need verification
    # @return [ActiveRecord::Relation<Geo::ProjectRegistry>] list of registries that need verification
    def fdw_find_registries_to_verify(batch_size:)
      repo_condition =
        local_registry_table[:repository_verification_checksum_sha].eq(nil)
          .and(local_registry_table[:last_repository_verification_failure].eq(nil))
          .and(fdw_repository_state_table[:repository_verification_checksum].not_eq(nil))
      wiki_condition =
        local_registry_table[:wiki_verification_checksum_sha].eq(nil)
          .and(local_registry_table[:last_wiki_verification_failure].eq(nil))
          .and(fdw_repository_state_table[:wiki_verification_checksum].not_eq(nil))

      Geo::ProjectRegistry
        .joins(fdw_inner_join_repository_state)
        .where(repo_condition.or(wiki_condition))
        .limit(batch_size)
    end

    # @return [ActiveRecord::Relation<Geo::ProjectRegistry>]
    def fdw_find_verified_wikis
      Geo::ProjectRegistry.verified_wikis.where(fdw_enabled_wikis)
    end

    def fdw_inner_join_repository_state
      local_registry_table
        .join(fdw_repository_state_table, Arel::Nodes::InnerJoin)
        .on(local_registry_table[:project_id].eq(fdw_repository_state_table[:project_id]))
        .join_sources
    end

    def fdw_enabled_wikis
      project_id_matcher =
        Geo::Fdw::ProjectFeature.arel_table[:project_id]
          .eq(Geo::ProjectRegistry.arel_table[:project_id])

      # Only read the IDs of projects with disabled wikis from the remote database
      Geo::Fdw::ProjectFeature
        .where(wiki_access_level: [::ProjectFeature::DISABLED])
        .where(project_id_matcher)
        .select('1')
        .exists
        .not
    end

    #
    # Legacy accessors (non FDW)
    #

    # @return [ActiveRecord::Relation<Project>] list of unsynced projects
    def legacy_find_unsynced_projects
      legacy_left_outer_join_registry_ids(
        current_node.projects,
        Geo::ProjectRegistry.pluck(:project_id),
        Project
      )
    end

    # @return [ActiveRecord::Relation<Project>] list of projects updated recently
    def legacy_find_projects_updated_recently
      registries = Geo::ProjectRegistry.dirty.retry_due.pluck(:project_id, :last_repository_synced_at)
      return Project.none if registries.empty?

      id_and_last_sync_values = registries.map do |id, last_repository_synced_at|
        "(#{id}, #{quote_value(last_repository_synced_at)})"
      end

      joined_relation = current_node.projects.joins(<<~SQL)
        INNER JOIN
        (VALUES #{id_and_last_sync_values.join(',')})
        project_registry(id, last_repository_synced_at)
        ON #{Project.table_name}.id = project_registry.id
      SQL

      joined_relation
    end

    def quote_value(value)
      ::Gitlab::SQL::Glob.q(value)
    end

    # @return [ActiveRecord::Relation<Geo::ProjectRegistry>] list of synced projects
    def legacy_find_synced_repositories
      legacy_find_project_registries(Geo::ProjectRegistry.synced_repos)
    end

    # @return [ActiveRecord::Relation<Geo::ProjectRegistry>] list of synced projects
    def legacy_find_synced_wikis
      legacy_inner_join_registry_ids(
        current_node.projects.with_wiki_enabled,
          Geo::ProjectRegistry.synced_wikis.pluck(:project_id),
          Project
      )
    end

    # @return [ActiveRecord::Relation<Geo::ProjectRegistry>] list of verified projects
    def legacy_find_verified_repositories
      legacy_find_project_registries(Geo::ProjectRegistry.verified_repos)
    end

    # @return [ActiveRecord::Relation<Geo::ProjectRegistry>] list of verified wikis
    def legacy_find_verified_wikis
      legacy_inner_join_registry_ids(
        current_node.projects.with_wiki_enabled,
          Geo::ProjectRegistry.verified_wikis.pluck(:project_id),
          Project
      )
    end

    # @return [ActiveRecord::Relation<Project>] list of synced projects
    def legacy_find_project_registries(project_registries)
      legacy_inner_join_registry_ids(
        current_node.projects,
        project_registries.pluck(:project_id),
        Project
      )
    end

    # @return [ActiveRecord::Relation<Project>] list of projects that sync has failed
    def legacy_find_filtered_failed_projects(type = nil)
      legacy_inner_join_registry_ids(
        find_filtered_failed_project_registries(type),
        current_node.projects.pluck(:id),
        Geo::ProjectRegistry,
        foreign_key: :project_id
      )
    end

    # @return [ActiveRecord::Relation<Project>] list of projects that verification has failed
    def legacy_find_filtered_verification_failed_projects(type = nil)
      legacy_inner_join_registry_ids(
        find_filtered_verification_failed_project_registries(type),
        current_node.projects.pluck(:id),
        Geo::ProjectRegistry,
        foreign_key: :project_id
      )
    end

    # @return [ActiveRecord::Relation<Geo::ProjectRegistry>] list of registries that need verification
    def legacy_find_registries_to_verify(batch_size:)
      repo_condition =
        local_registry_table[:repository_verification_checksum_sha].eq(nil)
          .and(local_registry_table[:last_repository_verification_failure].eq(nil))
      wiki_condition =
        local_registry_table[:wiki_verification_checksum_sha].eq(nil)
          .and(local_registry_table[:last_wiki_verification_failure].eq(nil))

      registries = Geo::ProjectRegistry
        .where(repo_condition.or(wiki_condition))
        .pluck(:project_id, repo_condition.to_sql, wiki_condition.to_sql)

      return Geo::ProjectRegistry.none if registries.empty?

      id_and_want_to_sync = registries.map do |project_id, want_to_sync_repo, want_to_sync_wiki|
        "(#{project_id}, #{quote_value(want_to_sync_repo)}, #{quote_value(want_to_sync_wiki)})"
      end

      project_registry_sync_table = Arel::Table.new(:project_registry_sync_table)

      joined_relation =
        ProjectRepositoryState.joins(<<~SQL_REPO)
          INNER JOIN
          (VALUES #{id_and_want_to_sync.join(',')})
          project_registry_sync_table(project_id, want_to_sync_repo, want_to_sync_wiki)
          ON #{legacy_repository_state_table.name}.project_id = project_registry_sync_table.project_id
        SQL_REPO

      project_ids = joined_relation
        .where(
          legacy_repository_state_table[:repository_verification_checksum].not_eq(nil)
            .and(project_registry_sync_table[:want_to_sync_repo].eq(true))
          .or(legacy_repository_state_table[:wiki_verification_checksum].not_eq(nil)
            .and(project_registry_sync_table[:want_to_sync_wiki].eq(true))))
        .limit(batch_size)
        .pluck(:project_id)

      Geo::ProjectRegistry.where(project_id: project_ids)
    end

    def local_registry_table
      Geo::ProjectRegistry.arel_table
    end

    def legacy_repository_state_table
      ::ProjectRepositoryState.arel_table
    end

    def fdw_project_table
      Geo::Fdw::Project.table_name
    end

    def fdw_repository_state_table
      Geo::Fdw::ProjectRepositoryState.arel_table
    end
  end
end
