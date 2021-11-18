# frozen_string_literal: true

class DropCiBuildTraceSections < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::SchemaHelpers

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_foreign_key_if_exists(:dep_ci_build_trace_sections, column: :project_id)
    end

    with_lock_retries do
      remove_foreign_key_if_exists(:dep_ci_build_trace_section_names, column: :project_id)
    end

    if table_exists?(:dep_ci_build_trace_sections)
      with_lock_retries do
        drop_table :dep_ci_build_trace_sections
      end
    end

    if table_exists?(:dep_ci_build_trace_section_names)
      with_lock_retries do
        drop_table :dep_ci_build_trace_section_names
      end
    end

    drop_function('trigger_91dc388a5fe6')
  end

  def down
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION trigger_91dc388a5fe6() RETURNS trigger
      LANGUAGE plpgsql
      AS $$
      BEGIN
        NEW."build_id_convert_to_bigint" := NEW."build_id";
        RETURN NEW;
      END;
      $$;
    SQL

    execute_in_transaction(<<~SQL, !table_exists?(:dep_ci_build_trace_section_names))
      CREATE TABLE dep_ci_build_trace_section_names (
        id integer NOT NULL,
        project_id integer NOT NULL,
        name character varying NOT NULL
      );

      CREATE SEQUENCE dep_ci_build_trace_section_names_id_seq
        AS integer
        START WITH 1
        INCREMENT BY 1
        NO MINVALUE
        NO MAXVALUE
        CACHE 1;

      ALTER SEQUENCE dep_ci_build_trace_section_names_id_seq OWNED BY dep_ci_build_trace_section_names.id;

      ALTER TABLE ONLY dep_ci_build_trace_section_names ALTER COLUMN id SET DEFAULT nextval('dep_ci_build_trace_section_names_id_seq'::regclass);
      ALTER TABLE ONLY dep_ci_build_trace_section_names ADD CONSTRAINT dep_ci_build_trace_section_names_pkey PRIMARY KEY (id);
    SQL

    execute_in_transaction(<<~SQL, !table_exists?(:dep_ci_build_trace_sections))
      CREATE TABLE dep_ci_build_trace_sections (
        project_id integer NOT NULL,
        date_start timestamp without time zone NOT NULL,
        date_end timestamp without time zone NOT NULL,
        byte_start bigint NOT NULL,
        byte_end bigint NOT NULL,
        build_id integer NOT NULL,
        section_name_id integer NOT NULL,
        build_id_convert_to_bigint bigint DEFAULT 0 NOT NULL
      );

      ALTER TABLE ONLY dep_ci_build_trace_sections ADD CONSTRAINT ci_build_trace_sections_pkey PRIMARY KEY (build_id, section_name_id);
      CREATE TRIGGER trigger_91dc388a5fe6 BEFORE INSERT OR UPDATE ON dep_ci_build_trace_sections FOR EACH ROW EXECUTE FUNCTION trigger_91dc388a5fe6();
    SQL

    add_concurrent_index :dep_ci_build_trace_section_names, [:project_id, :name], unique: true, name: 'index_dep_ci_build_trace_section_names_on_project_id_and_name'
    add_concurrent_index :dep_ci_build_trace_sections, :project_id, name: 'index_dep_ci_build_trace_sections_on_project_id'
    add_concurrent_index :dep_ci_build_trace_sections, :section_name_id, name: 'index_dep_ci_build_trace_sections_on_section_name_id'

    add_concurrent_foreign_key :dep_ci_build_trace_sections, :dep_ci_build_trace_section_names, column: :section_name_id, on_delete: :cascade, name: 'fk_264e112c66'
    add_concurrent_foreign_key :dep_ci_build_trace_sections, :projects, column: :project_id, on_delete: :cascade, name: 'fk_ab7c104e26'
    add_concurrent_foreign_key :dep_ci_build_trace_section_names, :projects, column: :project_id, on_delete: :cascade, name: 'fk_f8cd72cd26'
  end

  private

  def execute_in_transaction(sql, condition)
    return unless condition

    transaction do
      execute(sql)
    end
  end
end
