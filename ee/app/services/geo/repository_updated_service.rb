module Geo
  class RepositoryUpdatedService
    include ::Gitlab::Geo::ProjectLogHelpers

    RepositoryUpdateError = Class.new(StandardError)

    def initialize(project, params = {})
      @project = project
      @params  = params
      @refs    = params.fetch(:refs, [])
      @changes = params.fetch(:changes, [])
      @source  = params.fetch(:source, Geo::RepositoryUpdatedEvent::REPOSITORY)
    end

    def execute
      return false unless Gitlab::Geo.primary?

      reset_repository_checksum!
      create_repository_updated_event!

      true
    end

    private

    attr_reader :project, :refs, :changes, :source

    delegate :repository_state, to: :project

    def create_repository_updated_event!
      Geo::RepositoryUpdatedEventStore.new(
        project, refs: refs, changes: changes, source: source
      ).create
    end

    def reset_repository_checksum!
      return if repository_state.nil?

      repository_state.update!("#{repository_checksum_column}" => nil, "#{repository_failure_column}" => nil)
    rescue => e
      log_error('Cannot reset repository checksum', e)
      raise RepositoryUpdateError, "Cannot reset repository checksum: #{e}"
    end

    def repository_checksum_column
      "#{Geo::RepositoryUpdatedEvent.sources.key(source)}_verification_checksum"
    end

    def repository_failure_column
      "last_#{Geo::RepositoryUpdatedEvent.sources.key(source)}_verification_failure"
    end
  end
end
