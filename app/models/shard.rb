# frozen_string_literal: true

class Shard < ApplicationRecord
  # Store shard names from the configuration file in the database. This is not a
  # list of active shards - we just want to assign an immutable, unique ID to
  # every shard name for easy indexing / referencing.
  def self.populate!
    return unless table_exists?

    # The GitLab config does not change for the lifecycle of the process
    in_config = Gitlab.config.repositories.storages.keys.map(&:to_s)
    in_db = all.pluck(:name)

    # This may race with other processes creating shards at the same time, but
    # `by_name` will handle that correctly
    missing = in_config - in_db
    missing.map { |name| by_name(name) }
  end

  def self.by_name(name)
    safe_find_or_create_by(name: name)
  end
end
