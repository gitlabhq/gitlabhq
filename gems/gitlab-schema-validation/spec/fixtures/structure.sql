CREATE SEQUENCE missing_sequence;
CREATE SEQUENCE shared_audit_event_id_seq;
CREATE SEQUENCE abuse_events_id_seq;
CREATE SEQUENCE zoekt_repositories_id_seq;

ALTER SEQUENCE abuse_events_id_seq OWNED by abuse_events.id;
ALTER SEQUENCE zoekt_repositories_id_seq OWNED by zoekt_repositories.id;

CREATE INDEX missing_index ON events USING btree (created_at, author_id);

CREATE UNIQUE INDEX wrong_index ON table_name (column_name, column_name_2);

CREATE INDEX renamed_index ON events USING btree (id);

CREATE INDEX duplicated_index ON events USING btree (project_id);

CREATE INDEX swapped_index_1 ON events USING btree (target_id);

CREATE INDEX swapped_index_2 ON events USING btree (target_type);

CREATE UNIQUE INDEX "index" ON achievements USING btree (namespace_id, lower(name));

CREATE INDEX index_namespaces_public_groups_name_id ON namespaces USING btree (name, id) WHERE (((type)::text = 'Group'::text) AND (visibility_level = 20));

CREATE INDEX index_partitioned_table_on_id ON ONLY partitioned_table USING btree (id);

CREATE INDEX index_partitioned_table_on_column_name ON ONLY partitioned_table USING btree (column_name);

CREATE INDEX index_other_partitioned_table_on_column_name ON ONLY other_partitioned_table USING btree (column_name) WHERE (status = 0);

CREATE INDEX index_partitioned_table_on_column_name_2 ON ONLY partitioned_table USING btree (column_name_2);

CREATE INDEX index_partitioned_table_on_created_at ON ONLY partitioned_table USING btree (created_at);

CREATE INDEX index_partitioned_table_on_other_column ON ONLY partitioned_table USING btree (other_column);

CREATE INDEX index_public_partitioned_table_on_id ON ONLY public_partitioned_table USING btree (id);

CREATE INDEX partition_index ON gitlab_partitions_static.partitioned_table_1 USING btree (id);

CREATE INDEX partition_index_1 ON gitlab_partitions_static.partitioned_table_1 USING btree (column_name);

CREATE INDEX partition_index_2 ON gitlab_partitions_static.other_partitioned_table_1 USING btree (column_name) WHERE (status = 0);

CREATE INDEX renamed_partition_index ON gitlab_partitions_static.partitioned_table_3 USING btree (id);

CREATE INDEX wrong_partition_index ON gitlab_partitions_static.partitioned_table_1 USING btree (column_name_2);

CREATE INDEX redefined_partition_index ON gitlab_partitions_static.partitioned_table_7 USING btree (created_at);

CREATE INDEX missing_partition_index ON gitlab_partitions_static.partitioned_table_1 USING btree (other_column);

CREATE INDEX detached_partition_index ON gitlab_partitions_static.partitioned_table_6 USING btree (id);

CREATE INDEX relocated_partition_index ON gitlab_partitions_static.partitioned_table_8 USING btree (id);

CREATE INDEX standalone_partition_index ON gitlab_partitions_static.partitioned_table_5 USING btree (id);

CREATE INDEX public_partition_index_1 ON public_partitioned_table_1 USING btree (id);

CREATE INDEX public_partition_index_2 ON public_partitioned_table_2 USING btree (id);

CREATE UNIQUE INDEX index_on_deploy_keys_id_and_type_and_public ON keys USING btree (id, type) WHERE (public = true);

CREATE INDEX index_users_on_public_email_excluding_null_and_empty ON users USING btree (public_email) WHERE (((public_email)::text <> ''::text) AND (public_email IS NOT NULL));

CREATE TABLE test_table (
  id bigint NOT NULL,
  integer_column integer,
  integer_with_default_column integer DEFAULT 1,
  smallint_column smallint,
  smallint_with_default_column smallint DEFAULT 0 NOT NULL,
  numeric_column numeric NOT NULL,
  numeric_with_default_column numeric DEFAULT 1.0 NOT NULL,
  boolean_colum boolean,
  boolean_with_default_column_true boolean DEFAULT true NOT NULL,
  boolean_with_default_column_false boolean DEFAULT false NOT NULL,
  double_precision_column double precision,
  double_precision_with_default_column double precision DEFAULT 1.0,
  varying_column character varying,
  varying_with_default_column character varying DEFAULT 'DEFAULT'::character varying NOT NULL,
  varying_with_limit_column character varying(255),
  varying_with_limit_and_default_column character varying(255) DEFAULT 'DEFAULT'::character varying,
  text_column text NOT NULL,
  text_with_default_column text DEFAULT ''::text NOT NULL,
  array_column character varying(255)[] NOT NULL,
  array_with_default_column character varying(255)[] DEFAULT '{one,two}'::character varying[] NOT NULL,
  jsonb_column jsonb,
  jsonb_with_default_column jsonb DEFAULT '[]'::jsonb NOT NULL,
  timestamptz_column timestamp with time zone,
  timestamptz_with_default_column timestamp(6) with time zone DEFAULT now(),
  timestamp_column timestamp(6) without time zone NOT NULL,
  timestamp_with_default_column timestamp(6) without time zone DEFAULT '2022-01-23 00:00:00+00'::timestamp without time zone NOT NULL,
  date_column date,
  date_with_default_column date DEFAULT '2023-04-05',
  inet_column inet NOT NULL,
  inet_with_default_column inet DEFAULT '0.0.0.0'::inet NOT NULL,
  macaddr_column macaddr,
  macaddr_with_default_column macaddr DEFAULT '00-00-00-00-00-000'::macaddr NOT NULL,
  uuid_column uuid NOT NULL,
  uuid_with_default_column uuid DEFAULT '00000000-0000-0000-0000-000000000000'::uuid NOT NULL,
  bytea_column bytea,
  bytea_with_default_column bytea DEFAULT '\xDEADBEEF'::bytea,
  unmapped_column_type anyarray,
  partition_key bigint DEFAULT 1 NOT NULL,
  created_at timestamp with time zone DEFAULT now() NOT NULL,
  daterange date_range
) PARTITION BY HASH (partition_key, created_at);

CREATE TABLE ci_project_mirrors (
    id bigint NOT NULL,
    project_id integer NOT NULL,
    namespace_id integer NOT NULL
);

CREATE TABLE wrong_table (
  id bigint NOT NULL,
  description character varying(255) NOT NULL
);

CREATE TABLE extra_table_columns (
  id bigint NOT NULL,
  name character varying(255) NOT NULL
);

CREATE TABLE missing_table (
  id bigint NOT NULL,
  description text NOT NULL
);

CREATE TABLE missing_table_columns (
  id bigint NOT NULL,
  email character varying(255) NOT NULL
);

CREATE TABLE operations_user_lists (
  id bigint NOT NULL,
  project_id bigint NOT NULL,
  created_at timestamp with time zone NOT NULL,
  updated_at timestamp with time zone NOT NULL,
  iid integer NOT NULL,
  name character varying(255) NOT NULL,
  user_xids text DEFAULT ''::text NOT NULL
);

CREATE TRIGGER trigger AFTER INSERT ON public.t1 FOR EACH ROW EXECUTE FUNCTION t1();

CREATE TRIGGER wrong_trigger BEFORE UPDATE ON public.t2 FOR EACH ROW EXECUTE FUNCTION my_function();

CREATE TRIGGER missing_trigger_1 BEFORE INSERT OR UPDATE ON public.t3 FOR EACH ROW EXECUTE FUNCTION t3();

CREATE TRIGGER projects_loose_fk_trigger AFTER DELETE ON projects REFERENCING OLD TABLE AS old_table FOR EACH STATEMENT EXECUTE FUNCTION insert_into_loose_foreign_keys_deleted_records();

ALTER TABLE web_hooks
    ADD CONSTRAINT web_hooks_project_id_fkey FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;

ALTER TABLE ONLY issues
    ADD CONSTRAINT wrong_definition_fk FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE ONLY issues
    ADD CONSTRAINT missing_fk FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE ONLY bulk_import_configurations
    ADD CONSTRAINT fk_rails_536b96bff1 FOREIGN KEY (bulk_import_id) REFERENCES bulk_imports(id) ON DELETE CASCADE;

ALTER INDEX index_partitioned_table_on_id ATTACH PARTITION gitlab_partitions_static.partition_index;

ALTER INDEX index_partitioned_table_on_column_name ATTACH PARTITION gitlab_partitions_static.partition_index_1;

ALTER INDEX index_other_partitioned_table_on_column_name ATTACH PARTITION gitlab_partitions_static.partition_index_2;

ALTER INDEX index_partitioned_table_on_id ATTACH PARTITION gitlab_partitions_static.renamed_partition_index;

ALTER INDEX index_partitioned_table_on_column_name_2 ATTACH PARTITION gitlab_partitions_static.wrong_partition_index;

ALTER INDEX index_partitioned_table_on_created_at ATTACH PARTITION gitlab_partitions_static.redefined_partition_index;

ALTER INDEX index_partitioned_table_on_other_column ATTACH PARTITION gitlab_partitions_static.missing_partition_index;

ALTER INDEX index_partitioned_table_on_id ATTACH PARTITION gitlab_partitions_static.detached_partition_index;

ALTER INDEX index_partitioned_table_on_id ATTACH PARTITION gitlab_partitions_static.relocated_partition_index;

ALTER INDEX index_public_partitioned_table_on_id ATTACH PARTITION public_partition_index_1;

ALTER INDEX index_public_partitioned_table_on_id ATTACH PARTITION public_partition_index_2;
