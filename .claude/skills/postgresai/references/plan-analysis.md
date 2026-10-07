# Reading and iterating on plans

Run `joe explain` (ANALYZE, BUFFERS) for the real picture; `joe plan` only gives estimates.

## What to look at

- **Buffers** (`shared hit` / `read`): the most stable metric. Timing on a clone varies
  with cache state; buffer counts don't. Aim for few buffers, mostly hits.
- **Timing**: the first explain on a fresh clone is cold (tens of seconds with heavy reads).
  Measure the "before" plan twice and compare warm to warm.
- **Estimates vs actual rows**: a large mismatch points to stale statistics or
  correlated columns.
- **Seq Scan on large tables**, or `Rows Removed by Filter` much larger than rows
  returned: a missing or unsuitable index.
- **Sort / hash spilling to disk** (`Disk:`), and nested loops with many loops over
  big inner sets.
- **Index Scan vs Index Only Scan** and `Heap Fetches`.

## Iterating

1. `exec "CREATE INDEX ..."`, then `exec "ANALYZE <table>"` so statistics are fresh, then
   `explain`. Plan shape alone is not proof; confirm buffers drop.
2. Try a couple of column orders, partial indexes (`WHERE`), or query rewrites.
3. `CREATE INDEX` / `ANALYZE` on large tables can take minutes and `joe.sh` waits
   `JOE_WAIT_SECONDS` (default 600): raise it for big tables. On timeout the command keeps
   running; resume with the printed `postgresai joe result <id>`.
4. `reset` between unrelated experiments so earlier indexes don't distort results.

`hypo` (HypoPG) state was not observed to persist between CLI calls, so don't use it to
rule an index out. The argument string must not repeat
`hypo`. Correct: `postgresai joe hypo --project <p> "create index on t (c)"` or
`postgresai joe hypo --project <p> "desc"`. Wrong: `... hypo "hypo desc"`, which errors with
`invalid args given for the hypo command`.
