# frozen_string_literal: true

# Ignore dynamically managed partitions in static application schema
ActiveRecord::Tasks::DatabaseTasks.structure_dump_flags = ["-T", "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.*"]
