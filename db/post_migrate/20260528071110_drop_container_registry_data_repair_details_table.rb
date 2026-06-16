# frozen_string_literal: true

class DropContainerRegistryDataRepairDetailsTable < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def up
    drop_table :container_registry_data_repair_details
  end

  def down
    execute(<<~SQL)
      CREATE TABLE container_registry_data_repair_details (
          missing_count integer DEFAULT 0,
          project_id bigint NOT NULL,
          created_at timestamp with time zone NOT NULL,
          updated_at timestamp with time zone NOT NULL,
          status smallint DEFAULT 0 NOT NULL
      );

      ALTER TABLE ONLY container_registry_data_repair_details
          ADD CONSTRAINT container_registry_data_repair_details_pkey PRIMARY KEY (project_id);

      CREATE INDEX index_container_registry_data_repair_details_on_status
          ON container_registry_data_repair_details USING btree (status);

      ALTER TABLE ONLY container_registry_data_repair_details
          ADD CONSTRAINT fk_rails_b70d8111d9
          FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;
    SQL
  end
end
