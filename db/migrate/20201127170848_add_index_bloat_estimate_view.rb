# frozen_string_literal: true

class AddIndexBloatEstimateView < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute(<<~SQL)
      CREATE VIEW postgres_index_bloat_estimates AS
      -- Originally from: https://github.com/ioguix/pgsql-bloat-estimation/blob/master/btree/btree_bloat.sql
      -- WARNING: executed with a non-superuser role, the query inspect only index on tables you are granted to read.
      -- WARNING: rows with is_na = 't' are known to have bad statistics ("name" type is not supported).
      -- This query is compatible with PostgreSQL 8.2 and after
      SELECT nspname || '.' || idxname as identifier,
        CASE WHEN relpages > est_pages_ff
          THEN bs*(relpages-est_pages_ff)
          ELSE 0
        END::bigint AS bloat_size_bytes
      FROM (
        SELECT
            coalesce(1 +
              ceil(reltuples/floor((bs-pageopqdata-pagehdr)*fillfactor/(100*(4+nulldatahdrwidth)::float))), 0
            ) AS est_pages_ff,
            bs, nspname, tblname, idxname, relpages, is_na
        FROM (
            SELECT maxalign, bs, nspname, tblname, idxname, reltuples, relpages, idxoid, fillfactor,
                  ( index_tuple_hdr_bm +
                      maxalign - CASE -- Add padding to the index tuple header to align on MAXALIGN
                        WHEN index_tuple_hdr_bm%maxalign = 0 THEN maxalign
                        ELSE index_tuple_hdr_bm%maxalign
                      END
                    + nulldatawidth + maxalign - CASE -- Add padding to the data to align on MAXALIGN
                        WHEN nulldatawidth = 0 THEN 0
                        WHEN nulldatawidth::integer%maxalign = 0 THEN maxalign
                        ELSE nulldatawidth::integer%maxalign
                      END
                  )::numeric AS nulldatahdrwidth, pagehdr, pageopqdata, is_na
            FROM (
                SELECT n.nspname, i.tblname, i.idxname, i.reltuples, i.relpages,
                    i.idxoid, i.fillfactor, current_setting('block_size')::numeric AS bs,
                    CASE -- MAXALIGN: 4 on 32bits, 8 on 64bits (and mingw32 ?)
                      WHEN version() ~ 'mingw32' OR version() ~ '64-bit|x86_64|ppc64|ia64|amd64' THEN 8
                      ELSE 4
                    END AS maxalign,
                    /* per page header, fixed size: 20 for 7.X, 24 for others */
                    24 AS pagehdr,
                    /* per page btree opaque data */
                    16 AS pageopqdata,
                    /* per tuple header: add IndexAttributeBitMapData if some cols are null-able */
                    CASE WHEN max(coalesce(s.null_frac,0)) = 0
                        THEN 2 -- IndexTupleData size
                        ELSE 2 + (( 32 + 8 - 1 ) / 8) -- IndexTupleData size + IndexAttributeBitMapData size ( max num filed per index + 8 - 1 /8)
                    END AS index_tuple_hdr_bm,
                    /* data len: we remove null values save space using it fractionnal part from stats */
                    sum( (1-coalesce(s.null_frac, 0)) * coalesce(s.avg_width, 1024)) AS nulldatawidth,
                    max( CASE WHEN i.atttypid = 'pg_catalog.name'::regtype THEN 1 ELSE 0 END ) > 0 AS is_na
                FROM (
                    SELECT ct.relname AS tblname, ct.relnamespace, ic.idxname, ic.attpos, ic.indkey, ic.indkey[ic.attpos], ic.reltuples, ic.relpages, ic.tbloid, ic.idxoid, ic.fillfactor,
                        coalesce(a1.attnum, a2.attnum) AS attnum, coalesce(a1.attname, a2.attname) AS attname, coalesce(a1.atttypid, a2.atttypid) AS atttypid,
                        CASE WHEN a1.attnum IS NULL
                        THEN ic.idxname
                        ELSE ct.relname
                        END AS attrelname
                    FROM (
                        SELECT idxname, reltuples, relpages, tbloid, idxoid, fillfactor, indkey,
                            pg_catalog.generate_series(1,indnatts) AS attpos
                        FROM (
                            SELECT ci.relname AS idxname, ci.reltuples, ci.relpages, i.indrelid AS tbloid,
                                i.indexrelid AS idxoid,
                                coalesce(substring(
                                    array_to_string(ci.reloptions, ' ')
                                    from 'fillfactor=([0-9]+)')::smallint, 90) AS fillfactor,
                                i.indnatts,
                                pg_catalog.string_to_array(pg_catalog.textin(
                                    pg_catalog.int2vectorout(i.indkey)),' ')::int[] AS indkey
                            FROM pg_catalog.pg_index i
                            JOIN pg_catalog.pg_class ci ON ci.oid = i.indexrelid
                            WHERE ci.relam=(SELECT oid FROM pg_am WHERE amname = 'btree')
                            AND ci.relpages > 0
                        ) AS idx_data
                    ) AS ic
                    JOIN pg_catalog.pg_class ct ON ct.oid = ic.tbloid
                    LEFT JOIN pg_catalog.pg_attribute a1 ON
                        ic.indkey[ic.attpos] <> 0
                        AND a1.attrelid = ic.tbloid
                        AND a1.attnum = ic.indkey[ic.attpos]
                    LEFT JOIN pg_catalog.pg_attribute a2 ON
                        ic.indkey[ic.attpos] = 0
                        AND a2.attrelid = ic.idxoid
                        AND a2.attnum = ic.attpos
                  ) i
                  JOIN pg_catalog.pg_namespace n ON n.oid = i.relnamespace
                  JOIN pg_catalog.pg_stats s ON s.schemaname = n.nspname
                                            AND s.tablename = i.attrelname
                                            AND s.attname = i.attname
                  GROUP BY 1,2,3,4,5,6,7,8,9,10,11
            ) AS rows_data_stats
        ) AS rows_hdr_pdg_stats
      ) AS relation_stats
      WHERE nspname IN ("current_schema"(), 'gitlab_partitions_dynamic', 'gitlab_partitions_static') AND NOT is_na
      ORDER BY nspname, tblname, idxname;
    SQL
  end

  def down
    execute(<<~SQL)
      DROP VIEW postgres_index_bloat_estimates
    SQL
  end
end
