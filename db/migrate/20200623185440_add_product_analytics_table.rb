# frozen_string_literal: true

class AddProductAnalyticsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  include Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # Table is based on https://github.com/snowplow/snowplow/blob/master/4-storage/postgres-storage/sql/atomic-def.sql 6e07b1c, with the following differences:
  # * app_id varchar -> project_id integer (+ FK)
  # * Add `id bigserial`
  # * Hash partitioning based on `project_id`
  # * Timestamp columns: Change type to timestamp with time zone
  #
  # This table is part of the "product analytics experiment" and as such marked "experimental". The goal here is to
  # explore the product analytics as a MVP feature more. We are explicitly not spending time on relational modeling
  # here.
  #
  # We expect significant changes to the database part of this once the feature has been validated.
  # Therefore, we expect to drop the table when feature validation is complete. All data will be lost.
  def up
    with_lock_retries do
      execute <<~SQL
        CREATE TABLE "product_analytics_events_experimental" (
          id bigserial NOT NULL,
          -- App
          "project_id" integer NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
          "platform" varchar(255),
          -- Date/time
          "etl_tstamp" timestamp with time zone,
          "collector_tstamp" timestamp with time zone NOT NULL,
          "dvce_created_tstamp" timestamp with time zone,
          -- Date/time
          "event" varchar(128),
          "event_id" char(36) NOT NULL,
          "txn_id" integer,
          -- Versioning
          "name_tracker" varchar(128),
          "v_tracker" varchar(100),
          "v_collector" varchar(100) NOT NULL,
          "v_etl" varchar(100) NOT NULL,
          -- User and visit
          "user_id" varchar(255),
          "user_ipaddress" varchar(45),
          "user_fingerprint" varchar(50),
          "domain_userid" varchar(36),
          "domain_sessionidx" smallint,
          "network_userid" varchar(38),
          -- Location
          "geo_country" char(2),
          "geo_region" char(3),
          "geo_city" varchar(75),
          "geo_zipcode" varchar(15),
          "geo_latitude" double precision,
          "geo_longitude" double precision,
          "geo_region_name" varchar(100),
          -- IP lookups
          "ip_isp" varchar(100),
          "ip_organization" varchar(100),
          "ip_domain" varchar(100),
          "ip_netspeed" varchar(100),
          -- Page
          "page_url" text,
          "page_title" varchar(2000),
          "page_referrer" text,
          -- Page URL components
          "page_urlscheme" varchar(16),
          "page_urlhost" varchar(255),
          "page_urlport" integer,
          "page_urlpath" varchar(3000),
          "page_urlquery" varchar(6000),
          "page_urlfragment" varchar(3000),
          -- Referrer URL components
          "refr_urlscheme" varchar(16),
          "refr_urlhost" varchar(255),
          "refr_urlport" integer,
          "refr_urlpath" varchar(6000),
          "refr_urlquery" varchar(6000),
          "refr_urlfragment" varchar(3000),
          -- Referrer details
          "refr_medium" varchar(25),
          "refr_source" varchar(50),
          "refr_term" varchar(255),
          -- Marketing
          "mkt_medium" varchar(255),
          "mkt_source" varchar(255),
          "mkt_term" varchar(255),
          "mkt_content" varchar(500),
          "mkt_campaign" varchar(255),
          -- Custom structured event
          "se_category" varchar(1000),
          "se_action" varchar(1000),
          "se_label" varchar(1000),
          "se_property" varchar(1000),
          "se_value" double precision,
          -- Ecommerce
          "tr_orderid" varchar(255),
          "tr_affiliation" varchar(255),
          "tr_total" decimal(18,2),
          "tr_tax" decimal(18,2),
          "tr_shipping" decimal(18,2),
          "tr_city" varchar(255),
          "tr_state" varchar(255),
          "tr_country" varchar(255),
          "ti_orderid" varchar(255),
          "ti_sku" varchar(255),
          "ti_name" varchar(255),
          "ti_category" varchar(255),
          "ti_price" decimal(18,2),
          "ti_quantity" integer,
          -- Page ping
          "pp_xoffset_min" integer,
          "pp_xoffset_max" integer,
          "pp_yoffset_min" integer,
          "pp_yoffset_max" integer,
          -- User Agent
          "useragent" varchar(1000),
          -- Browser
          "br_name" varchar(50),
          "br_family" varchar(50),
          "br_version" varchar(50),
          "br_type" varchar(50),
          "br_renderengine" varchar(50),
          "br_lang" varchar(255),
          "br_features_pdf" boolean,
          "br_features_flash" boolean,
          "br_features_java" boolean,
          "br_features_director" boolean,
          "br_features_quicktime" boolean,
          "br_features_realplayer" boolean,
          "br_features_windowsmedia" boolean,
          "br_features_gears" boolean,
          "br_features_silverlight" boolean,
          "br_cookies" boolean,
          "br_colordepth" varchar(12),
          "br_viewwidth" integer,
          "br_viewheight" integer,
          -- Operating System
          "os_name" varchar(50),
          "os_family" varchar(50),
          "os_manufacturer" varchar(50),
          "os_timezone" varchar(50),
          -- Device/Hardware
          "dvce_type" varchar(50),
          "dvce_ismobile" boolean,
          "dvce_screenwidth" integer,
          "dvce_screenheight" integer,
          -- Document
          "doc_charset" varchar(128),
          "doc_width" integer,
          "doc_height" integer,
          -- Currency
          "tr_currency" char(3),
          "tr_total_base" decimal(18, 2),
          "tr_tax_base" decimal(18, 2),
          "tr_shipping_base" decimal(18, 2),
          "ti_currency" char(3),
          "ti_price_base" decimal(18, 2),
          "base_currency" char(3),
          -- Geolocation
          "geo_timezone" varchar(64),
          -- Click ID
          "mkt_clickid" varchar(128),
          "mkt_network" varchar(64),
          -- ETL tags
          "etl_tags" varchar(500),
          -- Time event was sent
          "dvce_sent_tstamp" timestamp with time zone,
          -- Referer
          "refr_domain_userid" varchar(36),
          "refr_dvce_tstamp" timestamp with time zone,
          -- Session ID
          "domain_sessionid" char(36),
          -- Derived timestamp
          "derived_tstamp" timestamp with time zone,
          -- Event schema
          "event_vendor" varchar(1000),
          "event_name" varchar(1000),
          "event_format" varchar(128),
          "event_version" varchar(128),
          -- Event fingerprint
          "event_fingerprint" varchar(128),
          -- True timestamp
          "true_tstamp" timestamp with time zone,
          PRIMARY KEY (id, project_id)
        ) PARTITION BY HASH (project_id)
          WITHOUT OIDS;

        CREATE INDEX index_product_analytics_events_experimental_project_and_time ON product_analytics_events_experimental (project_id, collector_tstamp);
      SQL

      create_hash_partitions :product_analytics_events_experimental, 64
    end
  end

  def down
    with_lock_retries do
      execute 'DROP TABLE product_analytics_events_experimental'
    end
  end
end
