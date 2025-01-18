# frozen_string_literal: true

module Repositories
  class ReplicateService < ::Repositories::BaseService
    Error = Class.new(StandardError)

    def execute(new_repository, type, partition_hint: "")
      new_repository.replicate(repository, partition_hint: partition_hint)

      new_checksum = new_repository.checksum
      checksum = repository.checksum

      return if new_checksum == checksum

      raise Error, format(s_(
        'ReplicateService|Failed to verify %{type} repository checksum from %{old} to %{new}'
      ), type: type, old: checksum, new: new_checksum)
    rescue StandardError => e
      new_repository.remove

      raise e
    end
  end
end
