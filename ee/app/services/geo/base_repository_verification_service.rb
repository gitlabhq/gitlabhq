# frozen_string_literal: true

module Geo
  class BaseRepositoryVerificationService
    include Delay
    include Gitlab::Geo::ProjectLogHelpers

    def execute
      raise NotImplementedError
    end

    private

    def calculate_checksum(repository)
      repository.checksum
    rescue Gitlab::Git::Repository::NoRepository, Gitlab::Git::Repository::InvalidRepository
      Gitlab::Git::Repository::EMPTY_REPOSITORY_CHECKSUM
    end

    def calculate_next_retry_attempt(resource, type)
      retry_count = resource.public_send("#{type}_retry_count").to_i + 1 # rubocop:disable GitlabSecurity/PublicSend
      [next_retry_time(retry_count), retry_count]
    end
  end
end
