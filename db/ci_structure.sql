SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: ci_instance_variables; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ci_instance_variables (
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


--
-- Name: ci_instance_variables_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ci_instance_variables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ci_instance_variables_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ci_instance_variables_id_seq OWNED BY public.ci_instance_variables.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: ci_instance_variables id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_instance_variables ALTER COLUMN id SET DEFAULT nextval('public.ci_instance_variables_id_seq'::regclass);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: ci_instance_variables ci_instance_variables_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ci_instance_variables
    ADD CONSTRAINT ci_instance_variables_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: index_ci_instance_variables_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_ci_instance_variables_on_key ON public.ci_instance_variables USING btree (key);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20210617101848');


