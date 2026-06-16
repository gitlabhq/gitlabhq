# frozen_string_literal: true

class AddPostgresIndexBloatEstimateFunction < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  FUNCTION_NAME = 'postgres_index_bloat_estimate'

  def up
    execute(<<~SQL)
      CREATE OR REPLACE FUNCTION #{FUNCTION_NAME}(p_schema name, p_idxname name)
      RETURNS bigint
      LANGUAGE sql
      STABLE
      PARALLEL SAFE
      AS $$
          SELECT
              CASE
                  WHEN ci.relpages::double precision > bloat.est_pages_ff
                      THEN c.bs::double precision * (ci.relpages::double precision - bloat.est_pages_ff)
                  ELSE 0::double precision
              END::bigint AS bloat_size_bytes
          FROM pg_class ci
          JOIN pg_index i      ON i.indexrelid = ci.oid
          JOIN pg_class ct     ON ct.oid = i.indrelid
          JOIN pg_namespace n  ON n.oid = ct.relnamespace

          CROSS JOIN LATERAL (
              SELECT
                  current_setting('block_size')::numeric AS bs,
                  CASE
                      WHEN version() ~ 'mingw32'::text
                        OR version() ~ '64-bit|x86_64|ppc64|ia64|amd64'::text THEN 8
                      ELSE 4
                  END AS maxalign,
                  24 AS pagehdr,
                  16 AS pageopqdata,
                  COALESCE(
                      "substring"(array_to_string(ci.reloptions, ' '::text),
                                  'fillfactor=([0-9]+)'::text)::smallint::integer,
                      90
                  ) AS fillfactor
          ) c

          CROSS JOIN LATERAL (
              SELECT
                  max(CASE WHEN COALESCE(a1.atttypid, a2.atttypid) = 'name'::regtype::oid
                           THEN 1 ELSE 0 END) > 0 AS is_na,
                  CASE WHEN max(COALESCE(s_t.null_frac, s_x.null_frac, 0::real)) = 0::double precision
                       THEN 2
                       ELSE 2 + (32 + 8 - 1) / 8
                  END AS index_tuple_hdr_bm,
                  sum((1::double precision - COALESCE(s_t.null_frac, s_x.null_frac, 0::real))
                      * COALESCE(s_t.avg_width, s_x.avg_width, 1024)::double precision) AS nulldatawidth
              FROM generate_series(1, i.indnatts::integer) AS gs(attpos)
              LEFT JOIN pg_attribute a1
                     ON (string_to_array(textin(int2vectorout(i.indkey)), ' '::text)::integer[])[gs.attpos] <> 0
                    AND a1.attrelid = i.indrelid
                    AND a1.attnum   = (string_to_array(textin(int2vectorout(i.indkey)), ' '::text)::integer[])[gs.attpos]
              LEFT JOIN pg_attribute a2
                     ON (string_to_array(textin(int2vectorout(i.indkey)), ' '::text)::integer[])[gs.attpos] = 0
                    AND a2.attrelid = ci.oid
                    AND a2.attnum   = gs.attpos
              LEFT JOIN pg_stats s_t
                     ON s_t.schemaname = n.nspname
                    AND s_t.tablename  = ct.relname
                    AND s_t.attname    = a1.attname
              LEFT JOIN pg_stats s_x
                     ON s_x.schemaname = n.nspname
                    AND s_x.tablename  = ci.relname
                    AND s_x.attname    = a2.attname
          ) agg

          CROSS JOIN LATERAL (
              SELECT
                  (
                      (agg.index_tuple_hdr_bm + c.maxalign
                       - CASE WHEN (agg.index_tuple_hdr_bm % c.maxalign) = 0 THEN c.maxalign
                              ELSE agg.index_tuple_hdr_bm % c.maxalign END)::double precision
                    + agg.nulldatawidth
                    + c.maxalign::double precision
                    - CASE WHEN agg.nulldatawidth = 0::double precision THEN 0
                           WHEN (agg.nulldatawidth::integer % c.maxalign) = 0 THEN c.maxalign
                           ELSE agg.nulldatawidth::integer % c.maxalign END::double precision
                  )::numeric AS nulldatahdrwidth
          ) hdr

          CROSS JOIN LATERAL (
              SELECT
                  COALESCE(
                      1::double precision + ceil(
                          ci.reltuples / floor(
                              ((c.bs - c.pageopqdata::numeric - c.pagehdr::numeric) * c.fillfactor::numeric)::double precision
                              / (100::double precision * (4::numeric + hdr.nulldatahdrwidth)::double precision)
                          )
                      ),
                      0::double precision
                  ) AS est_pages_ff,
                  agg.is_na
          ) bloat

          WHERE ci.relkind = 'i'
            AND ci.relname = p_idxname
            AND n.nspname  = p_schema
            AND ci.relam   = (SELECT oid FROM pg_am WHERE amname = 'btree'::name)
            AND ci.relpages > 0
            AND NOT bloat.is_na;
      $$;
    SQL
  end

  def down
    execute(<<~SQL)
      DROP FUNCTION IF EXISTS #{FUNCTION_NAME}(name, name)
    SQL
  end
end
