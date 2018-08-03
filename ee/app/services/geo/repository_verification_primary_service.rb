# frozen_string_literal: true

module Geo
  class RepositoryVerificationPrimaryService < BaseRepositoryVerificationService
    def initialize(project)
      @project = project
    end

    def execute
      verify_checksum(:repository, project.repository)
      verify_checksum(:wiki, project.wiki.repository)
    end

    private

    attr_reader :project

    def verify_checksum(type, repository)
      checksum = calculate_checksum(repository)
      update_repository_state!(type, checksum: checksum)
    rescue => e
      log_error("Error calculating the #{type} checksum", e, type: type)
      update_repository_state!(type, failure: e.message)
    end

    def update_repository_state!(type, checksum: nil, failure: nil)
      retry_at, retry_count =
        if failure.present?
          calculate_next_retry_attempt(repository_state, type)
        end

      repository_state.update!(
        "#{type}_verification_checksum" => checksum,
        "last_#{type}_verification_failure" => failure,
        "#{type}_retry_at" => retry_at,
        "#{type}_retry_count" => retry_count
      )
    end

    def repository_state
      @repository_state ||= project.repository_state || project.build_repository_state
    end
  end
end
