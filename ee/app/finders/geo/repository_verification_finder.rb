module Geo
  class RepositoryVerificationFinder
    def find_outdated_projects(batch_size:)
      Project.select(:id)
       .with_route
       .joins(:repository_state)
       .where(repository_outdated.or(wiki_outdated))
       .order(last_repository_updated_at_asc)
       .limit(batch_size)
    end

    def find_unverified_projects(batch_size:)
      Project.select(:id)
       .with_route
       .joins(left_join_repository_state)
       .where(repository_never_verified)
       .order(last_repository_updated_at_asc)
       .limit(batch_size)
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

    def left_join_repository_state
      projects_table
        .join(repository_state_table, Arel::Nodes::OuterJoin)
        .on(projects_table[:id].eq(repository_state_table[:project_id]))
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
  end
end
