module Geo
  class RepositoryUpdatedEventStore < EventStore
    self.event_type = :repository_updated_event

    private

    def build_event
      Geo::RepositoryUpdatedEvent.new(
        project: project,
        source: source,
        ref: ref,
        branches_affected: branches_affected,
        tags_affected: tags_affected,
        new_branch: push_to_new_branch?,
        remove_branch: push_remove_branch?
      )
    end

    def refs
      params.fetch(:refs, [])
    end

    def changes
      params.fetch(:changes, [])
    end

    def source
      params.fetch(:source, Geo::RepositoryUpdatedEvent::REPOSITORY)
    end

    def ref
      refs.first if refs.length == 1
    end

    def branches_affected
      refs.count { |ref| Gitlab::Git.branch_ref?(ref) }
    end

    def tags_affected
      refs.count { |ref| Gitlab::Git.tag_ref?(ref) }
    end

    def push_to_new_branch?
      changes.any? { |change| Gitlab::Git.branch_ref?(change[:ref]) && Gitlab::Git.blank_ref?(change[:before]) }
    end

    def push_remove_branch?
      changes.any? { |change| Gitlab::Git.branch_ref?(change[:ref]) && Gitlab::Git.blank_ref?(change[:after]) }
    end
  end
end
