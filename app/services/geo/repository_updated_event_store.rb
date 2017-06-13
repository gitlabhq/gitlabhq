module Geo
  class RepositoryUpdatedEventStore
    attr_reader :project, :source, :refs, :changes

    def initialize(project, refs: [], changes: [], source: Geo::RepositoryUpdatedEvent::REPOSITORY)
      @project = project
      @refs    = refs
      @changes = changes
      @source  = source
    end

    def create
      return unless Gitlab::Geo.primary?

      Geo::EventLog.transaction do
        event_log = Geo::EventLog.new
        event_log.repository_updated_event = build_event
        event_log.save!
      end
    rescue ActiveRecord::RecordInvalid
      log("#{Geo::PushEvent.sources.key(source).humanize} updated event could not be created")
    end

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

    def log(message)
      Rails.logger.info("#{self.class.name}: #{message} for project #{project.path_with_namespace} (#{project.id})")
    end
  end
end
