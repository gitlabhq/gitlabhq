module Geo
  class RepositoryVerificationPrimaryService
    include Delay
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
      retry_at, retry_count =
        if failure.present?
          retry_count = repository_state.public_send("#{type}_retry_count").to_i + 1 # rubocop:disable GitlabSecurity/PublicSend
          [next_retry_time(retry_count), retry_count]
        end

      repository_state.update!(
        "#{type}_verification_checksum" => checksum,
        "last_#{type}_verification_failure" => failure,
        "#{type}_retry_at" => retry_at,
        "#{type}_retry_count" => retry_count
      )
    end

    # To prevent the retry time from storing invalid dates in the database,
    # cap the max time to a week plus some random jitter value.
    def next_retry_time(retry_count)
      proposed_time = Time.now + delay(retry_count).seconds
      max_future_time = Time.now + 7.days + delay(1).seconds

      [proposed_time, max_future_time].min
    end

    def repository_state
      @repository_state ||= project.repository_state || project.build_repository_state
    end
  end
end
