# frozen_string_literal: true

# Ignore dynamically managed partitions in static application schema
ActiveRecord::SchemaDumper.ignore_tables += ["#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.*"]
