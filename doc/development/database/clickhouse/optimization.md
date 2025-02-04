---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Optimizing query execution
---

ClickHouse Inc has listed a [variety of optimization strategies](https://clickhouse.com/blog/clickhouse-faster-queries-with-projections-and-primary-indexes).

ClickHouse relies heavily on the structure of the primary index. However, in some cases, it's possible that queries rely on a column that's part of the primary index, but isn't the first column. See [Using multiple primary indexes](https://clickhouse.com/docs/en/guides/improving-query-performance/sparse-primary-indexes/sparse-primary-indexes-multiple) which offers several options in such cases. For example: using a data skipping index as a secondary index.

In cases of compound primary indexes, it's helpful to understand the data characteristics of key columns is also very helpful. They can allow the index to be more efficient. [Ordering key columns efficiently](https://clickhouse.com/docs/en/guides/improving-query-performance/sparse-primary-indexes/sparse-primary-indexes-cardinality) goes into details on these concepts.

ClickHouse blog also has a very good post, [Super charging your ClickHouse queries](https://clickhouse.com/blog/clickhouse-faster-queries-with-projections-and-primary-indexes), that outlines almost all of the approaches listed above.

It is possible to use [`EXPLAIN`](https://clickhouse.com/docs/en/sql-reference/statements/explain) statements with queries to get visible steps of the query pipeline. Note the different [types](https://clickhouse.com/docs/en/sql-reference/statements/explain#explain-types) of `EXPLAIN`.

Also, to get detailed query execution pipeline, you can toggle the logs level to `trace` via `clickhouse-client` and then execute the query.

For example:

```plaintext
$ clickhouse-client :) SET send_logs_level = 'trace'
$ clickhouse-client :) select count(traceID) from jaeger_index WHERE tenant = '12' AND service != 'jaeger-query' FORMAT Vertical ;

SELECT count(traceID)
FROM jaeger_index
WHERE (tenant = '12') AND (service != 'jaeger-query')
FORMAT Vertical

Query id: 6ce40daf-e1b1-4714-ab02-268246f3c5c9

[cluster-0-0-0] 2023.01.30 06:31:32.240819 [ 4991 ] {6ce40daf-e1b1-4714-ab02-268246f3c5c9} <Debug> executeQuery: (from 127.0.0.1:53654) select count(traceID) from jaeger_index WHERE tenant = '12' AND service != 'jaeger-query' FORMAT Vertical ; (stage: Complete)
....
[cluster-0-0-0] 2023.01.30 06:31:32.244071 [ 4991 ] {6ce40daf-e1b1-4714-ab02-268246f3c5c9} <Debug> InterpreterSelectQuery: MergeTreeWhereOptimizer: condition "service != 'jaeger-query'" moved to PREWHERE
[cluster-0-0-0] 2023.01.30 06:31:32.244420 [ 4991 ] {6ce40daf-e1b1-4714-ab02-268246f3c5c9} <Debug> InterpreterSelectQuery: MergeTreeWhereOptimizer: condition "service != 'jaeger-query'" moved to PREWHERE
....
[cluster-0-0-0] 2023.01.30 06:31:32.245153 [ 4991 ] {6ce40daf-e1b1-4714-ab02-268246f3c5c9} <Trace> InterpreterSelectQuery: FetchColumns -> Complete
[cluster-0-0-0] 2023.01.30 06:31:32.245255 [ 4991 ] {6ce40daf-e1b1-4714-ab02-268246f3c5c9} <Trace> InterpreterSelectQuery: Complete -> Complete
[cluster-0-0-0] 2023.01.30 06:31:32.245590 [ 4991 ] {6ce40daf-e1b1-4714-ab02-268246f3c5c9} <Debug> tracing_gcs.jaeger_index_local (66c6ca81-e20d-44dc-8101-92678fc24d99) (SelectExecutor): Key condition: (column 1 not in ['jaeger-query', 'jaeger-query']), unknown, (column 0 in ['12', '12']), and, and
[cluster-0-0-0] 2023.01.30 06:31:32.245784 [ 4991 ] {6ce40daf-e1b1-4714-ab02-268246f3c5c9} <Debug> tracing_gcs.jaeger_index_local (66c6ca81-e20d-44dc-8101-92678fc24d99) (SelectExecutor): MinMax index condition: unknown, unknown, and, unknown, and
[cluster-0-0-0] 2023.01.30 06:31:32.246239 [ 1503 ] {6ce40daf-e1b1-4714-ab02-268246f3c5c9} <Trace> tracing_gcs.jaeger_index_local (66c6ca81-e20d-44dc-8101-92678fc24d99) (SelectExecutor): Used generic exclusion search over index for part 202301_1512_21497_9164 with 4 steps
[cluster-0-0-0] 2023.01.30 06:31:32.246293 [ 1503 ] {6ce40daf-e1b1-4714-ab02-268246f3c5c9} <Trace> tracing_gcs.jaeger_index_local (66c6ca81-e20d-44dc-8101-92678fc24d99) (SelectExecutor): Used generic exclusion search over index for part 202301_21498_24220_677 with 1 steps
[cluster-0-0-0] 2023.01.30 06:31:32.246488 [ 4991 ] {6ce40daf-e1b1-4714-ab02-268246f3c5c9} <Debug> tracing_gcs.jaeger_index_local (66c6ca81-e20d-44dc-8101-92678fc24d99) (SelectExecutor): Selected 2/2 parts by partition key, 1 parts by primary key, 2/4 marks by primary key, 2 marks to read from 1 ranges
[cluster-0-0-0] 2023.01.30 06:31:32.246591 [ 4991 ] {6ce40daf-e1b1-4714-ab02-268246f3c5c9} <Trace> MergeTreeInOrderSelectProcessor: Reading 1 ranges in order from part 202301_1512_21497_9164, approx. 16384 rows starting from 0
[cluster-0-0-0] 2023.01.30 06:31:32.642095 [ 348 ] {6ce40daf-e1b1-4714-ab02-268246f3c5c9} <Trace> AggregatingTransform: Aggregating
[cluster-0-0-0] 2023.01.30 06:31:32.642193 [ 348 ] {6ce40daf-e1b1-4714-ab02-268246f3c5c9} <Trace> Aggregator: An entry for key=16426982211452591884 found in cache: sum_of_sizes=2, median_size=1
[cluster-0-0-0] 2023.01.30 06:31:32.642210 [ 348 ] {6ce40daf-e1b1-4714-ab02-268246f3c5c9} <Trace> Aggregator: Aggregation method: without_key
[cluster-0-0-0] 2023.01.30 06:31:32.642330 [ 348 ] {6ce40daf-e1b1-4714-ab02-268246f3c5c9} <Debug> AggregatingTransform: Aggregated. 3211 to 1 rows (from 50.18 KiB) in 0.395452983 sec. (8119.802 rows/sec., 126.89 KiB/sec.)
[cluster-0-0-0] 2023.01.30 06:31:32.642343 [ 348 ] {6ce40daf-e1b1-4714-ab02-268246f3c5c9} <Trace> Aggregator: Merging aggregated data
Row 1:
──────
count(traceID): 3211
[cluster-0-0-0] 2023.01.30 06:31:32.642887 [ 4991 ] {6ce40daf-e1b1-4714-ab02-268246f3c5c9} <Information> executeQuery: Read 16384 rows, 620.52 KiB in 0.401978272 sec., 40758 rows/sec., 1.51 MiB/sec.
[cluster-0-0-0] 2023.01.30 06:31:32.645232 [ 4991 ] {6ce40daf-e1b1-4714-ab02-268246f3c5c9} <Debug> MemoryTracker: Peak memory usage (for query): 831.98 KiB.
[cluster-0-0-0] 2023.01.30 06:31:32.645251 [ 4991 ] {6ce40daf-e1b1-4714-ab02-268246f3c5c9} <Debug> TCPHandler: Processed in 0.404908496 sec.

1 row in set. Elapsed: 0.402 sec. Processed 16.38 thousand rows, 635.41 KB (40.71 thousand rows/s., 1.58 MB/s.)
```
