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

--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: abuse_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.abuse_reports (
    id integer NOT NULL,
    reporter_id integer,
    user_id integer,
    message text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    message_html text,
    cached_markdown_version integer
);


--
-- Name: abuse_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.abuse_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



--
-- Name: abuse_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.abuse_reports ALTER COLUMN id SET DEFAULT nextval('public.abuse_reports_id_seq'::regclass);


--
--
-- Name: abuse_reports abuse_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.abuse_reports
    ADD CONSTRAINT abuse_reports_pkey PRIMARY KEY (id);

--
-- Name: index_abuse_reports_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_abuse_reports_on_user_id ON public.abuse_reports USING btree (user_id);



INSERT INTO "schema_migrations" (version) VALUES
('20200305121159'),
('20200306095654'),
('20200306160521'),
('20200306170211'),
('20200306170321'),
('20200306170531'),
('20200309140540'),
('20200309195209'),
('20200309195710'),
('20200310132654'),
('20200310135823');


