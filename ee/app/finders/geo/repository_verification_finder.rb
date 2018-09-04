module Geo
  class RepositoryVerificationFinder
    def initialize(shard_name: nil)
      @shard_name = shard_name
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def find_failed_repositories(batch_size:)
      query = build_query_to_find_failed_projects(type: :repository, batch_size: batch_size)
      cte   = Gitlab::SQL::CTE.new(:failed_repositories, query)

      Project.with(cte.to_arel)
             .from(cte.alias_to(projects_table))
             .order("projects.repository_retry_at ASC")
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_failed_wikis(batch_size:)
      query = build_query_to_find_failed_projects(type: :wiki, batch_size: batch_size)
      cte   = Gitlab::SQL::CTE.new(:failed_wikis, query)

      Project.with(cte.to_arel)
             .from(cte.alias_to(projects_table))
             .order("projects.wiki_retry_at ASC")
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_outdated_projects(batch_size:)
      query = build_query_to_find_outdated_projects(batch_size: batch_size)
      cte   = Gitlab::SQL::CTE.new(:outdated_projects, query)

      Project.with(cte.to_arel)
             .from(cte.alias_to(projects_table))
             .order(last_repository_updated_at_asc)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def find_unverified_projects(batch_size:)
      relation =
        Project.select(:id)
         .with_route
         .joins(left_join_repository_state)
         .where(repository_never_verified)
         .limit(batch_size)

      relation = apply_shard_restriction(relation) if shard_name.present?
      relation
    end
    # rubocop: enable CodeReuse/ActiveRecord

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

    private

    attr_reader :shard_name

    # rubocop: disable CodeReuse/ActiveRecord
    def build_query_to_find_failed_projects(type:, batch_size:)
      query =
        projects_table
          .join(repository_state_table).on(project_id_matcher)
          .project(projects_table[:id], repository_state_table["#{type}_retry_at"])
          .where(repository_state_table["last_#{type}_verification_failure"].not_eq(nil))
          .take(batch_size)

      query = apply_shard_restriction(query) if shard_name.present?
      query
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # rubocop: disable CodeReuse/ActiveRecord
    def build_query_to_find_outdated_projects(batch_size:)
      query =
        projects_table
          .join(repository_state_table).on(project_id_matcher)
          .project(projects_table[:id], projects_table[:last_repository_updated_at])
          .where(repository_outdated.or(wiki_outdated))
          .take(batch_size)

      query = apply_shard_restriction(query) if shard_name.present?
      query
    end
    # rubocop: enable CodeReuse/ActiveRecord

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

    # rubocop: disable CodeReuse/ActiveRecord
    def apply_shard_restriction(relation)
      relation.where(projects_table[:repository_storage].eq(shard_name))
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
