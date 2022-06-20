# frozen_string_literal: true

namespace :gitlab do
  namespace :db do
    namespace :decomposition do
      namespace :rollback do
        SEQUENCE_NAME_MATCHER = /nextval\('([a-z_]+)'::regclass\)/.freeze

        desc 'Bump all the CI tables sequences on the Main Database'
        task :bump_ci_sequences, [:increase_by] => :environment do |_t, args|
          increase_by = args.increase_by.to_i
          if increase_by < 1
            puts 'Please specify a positive integer `increase_by` value'.color(:red)
            puts 'Example: rake gitlab:db:decomposition:rollback:bump_ci_sequences[100000]'.color(:green)
            exit 1
          end

          sequences_by_gitlab_schema(ApplicationRecord, :gitlab_ci).each do |sequence_name|
            increment_sequence_by(ApplicationRecord.connection, sequence_name, increase_by)
          end
        end
      end
    end
  end
end

# base_model is to choose which connection to use to query the tables
# gitlab_schema, can be 'gitlab_main', 'gitlab_ci', 'gitlab_shared'
def sequences_by_gitlab_schema(base_model, gitlab_schema)
  tables = Gitlab::Database::GitlabSchema.tables_to_schema.select do |_table_name, schema_name|
    schema_name == gitlab_schema
  end.keys

  models = tables.map do |table|
    model = Class.new(base_model)
    model.table_name = table
    model
  end

  sequences = []
  models.each do |model|
    model.columns.each do |column|
      match_result = column.default_function&.match(SEQUENCE_NAME_MATCHER)
      next unless match_result

      sequences << match_result[1]
    end
  end

  sequences
end

# This method is going to increase the sequence next_value by:
#  - increment_by + 1 if the sequence has the attribute is_called = True (which is the common case)
#  - increment_by if the sequence has the attribute is_called = False (for example, a newly created sequence)
# It uses ALTER SEQUENCE as a safety mechanism to avoid that no concurrent insertions
# will cause conflicts on the sequence.
# This is because ALTER SEQUENCE blocks concurrent nextval, currval, lastval, and setval calls.
def increment_sequence_by(connection, sequence_name, increment_by)
  connection.transaction do
    # The first call is to make sure that the sequence's is_called value is set to `true`
    # This guarantees that the next call to `nextval` will increase the sequence by `increment_by`
    connection.select_value("SELECT nextval($1)", nil, [sequence_name])
    connection.execute("ALTER SEQUENCE #{sequence_name} INCREMENT BY #{increment_by}")
    connection.select_value("select nextval($1)", nil, [sequence_name])
    connection.execute("ALTER SEQUENCE #{sequence_name} INCREMENT BY 1")
  end
end
