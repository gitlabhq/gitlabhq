CREATE TABLE ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);

CREATE TABLE ci_instance_variables (
    id bigint NOT NULL,
    variable_type smallint DEFAULT 1 NOT NULL,
    masked boolean DEFAULT false,
    protected boolean DEFAULT false,
    key text NOT NULL,
    encrypted_value text,
    encrypted_value_iv text,
    CONSTRAINT check_07a45a5bcb CHECK ((char_length(encrypted_value_iv) <= 255)),
    CONSTRAINT check_5aede12208 CHECK ((char_length(key) <= 255)),
    CONSTRAINT check_956afd70f1 CHECK ((char_length(encrypted_value) <= 13579))
);

CREATE SEQUENCE ci_instance_variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE ci_instance_variables_id_seq OWNED BY ci_instance_variables.id;

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);

ALTER TABLE ONLY ci_instance_variables ALTER COLUMN id SET DEFAULT nextval('ci_instance_variables_id_seq'::regclass);

ALTER TABLE ONLY ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);

ALTER TABLE ONLY ci_instance_variables
    ADD CONSTRAINT ci_instance_variables_pkey PRIMARY KEY (id);

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);

CREATE UNIQUE INDEX index_ci_instance_variables_on_key ON ci_instance_variables USING btree (key);
