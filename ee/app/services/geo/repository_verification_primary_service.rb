module Geo
  class RepositoryVerificationPrimaryService
    include Gitlab::Geo::ProjectLogHelpers

    def initialize(project)
      @project = project
    end

    def execute
      calculate_repository_checksum
      calculate_wiki_checksum
    end

    private

    attr_reader :project

    def calculate_repository_checksum
      calculate_checksum(:repository, project.repository)
    end

    def calculate_wiki_checksum
      calculate_checksum(:wiki, project.wiki.repository)
    end

    def calculate_checksum(type, repository)
      update_repository_state!(type, checksum: repository.checksum)
    rescue Gitlab::Git::Repository::NoRepository, Gitlab::Git::Repository::InvalidRepository
      update_repository_state!(type, checksum: Gitlab::Git::Repository::EMPTY_REPOSITORY_CHECKSUM)
    rescue => e
      log_error('Error calculating the repository checksum', e, type: type)
      update_repository_state!(type, failure: e.message)
    end

    def update_repository_state!(type, checksum: nil, failure: nil)
      repository_state.update!(
        "#{type}_verification_checksum" => checksum,
        "last_#{type}_verification_failure" => failure
      )
    end

    def repository_state
      @repository_state ||= project.repository_state || project.build_repository_state
    end
  end
end
