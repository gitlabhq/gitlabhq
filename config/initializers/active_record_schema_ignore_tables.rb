# Ignore table used temporarily in background migration
ActiveRecord::SchemaDumper.ignore_tables = ["untracked_files_for_uploads"]

# Ignore dynamically managed partitions in static application schema
ActiveRecord::SchemaDumper.ignore_tables += ["#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.*"]
