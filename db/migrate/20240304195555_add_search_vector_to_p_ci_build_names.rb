# frozen_string_literal: true

class AddSearchVectorToPCiBuildNames < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  enable_lock_retries!

  def up
    execute <<~SQL
      ALTER TABLE p_ci_build_names
        ADD COLUMN search_vector tsvector
          GENERATED ALWAYS AS
            (to_tsvector('english', COALESCE(name, ''))) STORED;

      CREATE INDEX index_p_ci_build_names_on_search_vector ON p_ci_build_names USING gin (search_vector);
    SQL
  end

  def down
    remove_column :p_ci_build_names, :search_vector
  end
end
