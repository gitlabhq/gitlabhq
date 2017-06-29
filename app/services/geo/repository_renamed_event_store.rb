module Geo
  class RepositoryRenamedEventStore
    attr_reader :project, :old_path, :old_path_with_namespace

    def initialize(project, old_path:, old_path_with_namespace:)
      @project = project
      @old_path = old_path
      @old_path_with_namespace = old_path_with_namespace
    end

    def create
      return unless Gitlab::Geo.primary?

      Geo::EventLog.transaction do
        event_log = Geo::EventLog.new
        event_log.repository_renamed_event = build_event
        event_log.save!
      end
    rescue ActiveRecord::RecordInvalid
      log("Renamed event could not be created")
    end

    private

    def build_event
      Geo::RepositoryRenamedEvent.new(
        project: project,
        repository_storage_name: project.repository.storage,
        repository_storage_path: project.repository_storage_path,
        old_path_with_namespace: old_path_with_namespace,
        new_path_with_namespace: project.full_path,
        old_wiki_path_with_namespace: old_wiki_path_with_namespace,
        new_wiki_path_with_namespace: new_wiki_path_with_namespace,
        old_path: old_path,
        new_path: project.path
      )
    end

    def old_wiki_path_with_namespace
      "#{old_path_with_namespace}.wiki"
    end

    def new_wiki_path_with_namespace
      project.wiki.path_with_namespace
    end

    def log(message)
      Rails.logger.info("#{self.class.name}: #{message} for project #{project.path_with_namespace} (#{project.id})")
    end
  end
end
