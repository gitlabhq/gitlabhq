module Geo
  class RepositoryVerificationFinder
    attr_reader :shard_name

    def initialize(shard_name: nil)
      @shard_name = shard_name
    end

    def find_outdated_projects(batch_size:)
      cte_definition =
        projects_table
          .join(repository_state_table).on(project_id_matcher)
          .project(projects_table[:id], projects_table[:last_repository_updated_at])
          .where(repository_outdated.or(wiki_outdated))
          .take(batch_size)

      if shard_name.present?
        cte_definition = shard_restriction(cte_definition)
      end

      cte_table    = Arel::Table.new(:outdated_projects)
      composed_cte = Arel::Nodes::As.new(cte_table, cte_definition)
      alias_to     = Arel::Nodes::As.new(cte_table, projects_table)

      Project.with(composed_cte)
             .from(alias_to)
             .order(last_repository_updated_at_asc)
    end

    def find_unverified_projects(batch_size:)
      relation =
        Project.select(:id)
         .with_route
         .joins(left_join_repository_state)
         .where(repository_never_verified)
         .limit(batch_size)

      if shard_name.present?
        relation = shard_restriction(relation)
      end

      relation
    end

    def count_verified_repositories
      Project.verified_repos.count
    end

    def count_verified_wikis
      Project.verified_wikis.count
    end

    def count_verification_failed_repositories
      Project.verification_failed_repos.count
    end

    def count_verification_failed_wikis
      Project.verification_failed_wikis.count
    end

    protected

    def projects_table
      Project.arel_table
    end

    def repository_state_table
      ProjectRepositoryState.arel_table
    end

    def project_id_matcher
      projects_table[:id].eq(repository_state_table[:project_id])
    end

    def left_join_repository_state
      projects_table
        .join(repository_state_table, Arel::Nodes::OuterJoin)
        .on(project_id_matcher)
        .join_sources
    end

    def repository_outdated
      repository_state_table[:repository_verification_checksum].eq(nil)
        .and(repository_state_table[:last_repository_verification_failure].eq(nil))
    end

    def wiki_outdated
      repository_state_table[:wiki_verification_checksum].eq(nil)
        .and(repository_state_table[:last_wiki_verification_failure].eq(nil))
    end

    def repository_never_verified
      repository_state_table[:project_id].eq(nil)
    end

    def last_repository_updated_at_asc
      Gitlab::Database.nulls_last_order('projects.last_repository_updated_at', 'ASC')
    end

    def shard_restriction(relation)
      relation.where(projects_table[:repository_storage].eq(shard_name))
    end
  end
end
