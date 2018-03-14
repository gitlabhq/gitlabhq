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
          fdw_find_enabled_wikis
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
          find_verified_wikis
        end

      relation.count
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

    # find all registries that need a repository or wiki verified
    def find_registries_to_verify
      if use_legacy_queries?
        legacy_find_registries_to_verify
      else
        fdw_find_registries_to_verify
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

    def find_verified_wikis
      Geo::ProjectRegistry.verified_wikis
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

    def conditions_for_verification(type, use_fdw = true)
      last_verification_failed  = "last_#{type}_verification_failed".to_sym
      verification_checksum     = "#{type}_verification_checksum".to_sym
      last_verification_at      = "last_#{type}_verification_at".to_sym

      state_arel = use_fdw ? fdw_repository_state_arel : legacy_repository_state_arel

      # primary verification did not fail
      primary_verification_not_failed = state_arel[last_verification_failed].eq(false)

      # primary checksum is not NULL
      primary_has_checksum = state_arel[verification_checksum].not_eq(nil)

      # primary was verified later than the secondary verification
      primary_recently_verified = state_arel[last_verification_at].gt(registry_arel[last_verification_at])
                                    .or(registry_arel[last_verification_at].eq(nil))

      # secondary verification failed and the last verification was over 24.hours.ago
      # this allows us to retry any verification failures if they haven't already corrected themselves
      secondary_failure_period = registry_arel[last_verification_at].lt(24.hours.ago)
                                   .and(registry_arel[last_verification_failed].eq(true))

      primary_verification_not_failed
        .and(primary_has_checksum)
        .and(primary_recently_verified)
        .or(secondary_failure_period)
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
    def fdw_find_enabled_wikis
      project_id_matcher =
        Geo::Fdw::ProjectFeature.arel_table[:project_id]
          .eq(Geo::ProjectRegistry.arel_table[:project_id])

      # Only read the IDs of projects with disabled wikis from the remote database
      not_exist = Geo::Fdw::ProjectFeature
        .where(wiki_access_level: [::ProjectFeature::DISABLED, nil])
        .where(project_id_matcher)
        .select('1')
        .exists
        .not

      Geo::ProjectRegistry.synced_wikis.where(not_exist)
    end

    # @return [ActiveRecord::Relation<Geo::Fdw::Project>]
    def fdw_find_projects_updated_recently
      Geo::Fdw::Project.joins("INNER JOIN project_registry ON project_registry.project_id = #{fdw_project_table}.id")
          .merge(Geo::ProjectRegistry.dirty)
          .merge(Geo::ProjectRegistry.retry_due)
    end

    # find all registries that need a repository or wiki verified
    # @return [ActiveRecord::Relation<Geo::ProjectRegistry>] list of registries that need verification
    def fdw_find_registries_to_verify
      Geo::ProjectRegistry
        .joins("LEFT OUTER JOIN #{fdw_repository_state_table} ON #{fdw_repository_state_table}.project_id = project_registry.project_id")
        .where(conditions_for_verification(:repository, true).or(conditions_for_verification(:wiki, true)))
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

    # @return [ActiveRecord::Relation<Geo::ProjectRegistry>] list of verified projects
    def legacy_find_verified_wikis
      legacy_find_project_registries(Geo::ProjectRegistry.verified_wikis)
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
    def legacy_find_registries_to_verify
      registries = Geo::ProjectRegistry
        .pluck(:project_id, :last_repository_verification_at, :last_wiki_verification_at,
               :last_repository_verification_failed, :last_wiki_verification_failed)

      return Geo::ProjectRegistry.none if registries.empty?

      id_and_values = registries.map do |project_id, repo_at, wiki_at, repo_failed, wiki_failed|
        "(#{project_id}, to_timestamp(#{repo_at.to_i}), to_timestamp(#{wiki_at.to_i}),
          #{quote_value(repo_failed)}, #{quote_value(wiki_failed)})"
      end

      joined_relation = ProjectRepositoryState.joins(<<~SQL)
        INNER JOIN
        (VALUES #{id_and_values.join(',')})
        project_registry(project_id, last_repository_verification_at, last_wiki_verification_at,
                         last_repository_verification_failed, last_wiki_verification_failed)
        ON #{ProjectRepositoryState.table_name}.project_id = project_registry.project_id
      SQL

      project_ids = joined_relation
        .where(conditions_for_verification(:repository, false).or(conditions_for_verification(:wiki, false)))
        .pluck(:project_id)

      ::Geo::ProjectRegistry.where(project_id: project_ids)
    end

    private

    def registry_arel
      Geo::ProjectRegistry.arel_table
    end

    def fdw_repository_state_arel
      Geo::Fdw::ProjectRepositoryState.arel_table
    end

    def legacy_repository_state_arel
      ::ProjectRepositoryState.arel_table
    end

    def fdw_project_table
      Geo::Fdw::Project.table_name
    end

    def fdw_repository_state_table
      Geo::Fdw::ProjectRepositoryState.table_name
    end
  end
end
