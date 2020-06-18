SET search_path=public;

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;

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

CREATE SEQUENCE public.abuse_reports_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE ONLY public.abuse_reports ALTER COLUMN id SET DEFAULT nextval('public.abuse_reports_id_seq'::regclass);

ALTER TABLE ONLY public.abuse_reports
    ADD CONSTRAINT abuse_reports_pkey PRIMARY KEY (id);

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

