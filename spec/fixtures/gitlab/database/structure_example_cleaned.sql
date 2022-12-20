CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE abuse_reports (
    id integer NOT NULL,
    reporter_id integer,
    user_id integer,
    message text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    message_html text,
    cached_markdown_version integer
);

CREATE SEQUENCE abuse_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE ONLY abuse_reports ALTER COLUMN id SET DEFAULT nextval('abuse_reports_id_seq'::regclass);

ALTER TABLE ONLY abuse_reports
    ADD CONSTRAINT abuse_reports_pkey PRIMARY KEY (id);

CREATE INDEX index_abuse_reports_on_user_id ON abuse_reports USING btree (user_id);

CREATE FUNCTION gitlab_schema_prevent_write() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF COALESCE(NULLIF(current_setting(CONCAT('lock_writes.', TG_TABLE_NAME), true), ''), 'true') THEN
      RAISE EXCEPTION 'Table: "%" is write protected within this Gitlab database.', TG_TABLE_NAME
        USING ERRCODE = 'modifying_sql_data_not_permitted',
        HINT = 'Make sure you are using the right database connection';
END IF;
RETURN NEW;
END
$$;
