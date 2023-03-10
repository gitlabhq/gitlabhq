CREATE INDEX missing_index ON events USING btree (created_at, author_id);

CREATE UNIQUE INDEX wrong_index ON table_name (column_name, column_name_2);

CREATE UNIQUE INDEX "index" ON achievements USING btree (namespace_id, lower(name));

CREATE INDEX index_namespaces_public_groups_name_id ON namespaces USING btree (name, id) WHERE (((type)::text = 'Group'::text) AND (visibility_level = 20));

CREATE UNIQUE INDEX index_on_deploy_keys_id_and_type_and_public ON keys USING btree (id, type) WHERE (public = true);

CREATE INDEX index_users_on_public_email_excluding_null_and_empty ON users USING btree (public_email) WHERE (((public_email)::text <> ''::text) AND (public_email IS NOT NULL));

ALTER TABLE ONLY bulk_import_configurations
    ADD CONSTRAINT fk_rails_536b96bff1 FOREIGN KEY (bulk_import_id) REFERENCES bulk_imports(id) ON DELETE CASCADE;

CREATE TABLE ci_project_mirrors (
    id bigint NOT NULL,
    project_id integer NOT NULL,
    namespace_id integer NOT NULL
);

CREATE TRIGGER trigger AFTER INSERT ON public.t1 FOR EACH ROW EXECUTE FUNCTION t1();

CREATE TRIGGER wrong_trigger BEFORE UPDATE ON public.t2 FOR EACH ROW EXECUTE FUNCTION my_function();

CREATE TRIGGER missing_trigger_1 BEFORE INSERT OR UPDATE ON public.t3 FOR EACH ROW EXECUTE FUNCTION t3();

CREATE TRIGGER projects_loose_fk_trigger AFTER DELETE ON projects REFERENCING OLD TABLE AS old_table FOR EACH STATEMENT EXECUTE FUNCTION insert_into_loose_foreign_keys_deleted_records();
