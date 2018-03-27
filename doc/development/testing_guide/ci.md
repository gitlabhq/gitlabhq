# GitLab tests in the Continuous Integration (CI) context

### Test suite parallelization on the CI

Our current CI parallelization setup is as follows:

1. The `knapsack` job in the prepare stage that is supposed to ensure we have a
  `knapsack/${CI_PROJECT_NAME}/rspec_report-master.json` file:
  - The `knapsack/${CI_PROJECT_NAME}/rspec_report-master.json` file is fetched
    from S3, if it's not here we initialize the file with `{}`.
1. Each `rspec x y` job are run with `knapsack rspec` and should have an evenly
  distributed share of tests:
  - It works because the jobs have access to the
    `knapsack/${CI_PROJECT_NAME}/rspec_report-master.json` since the "artifacts
    from all previous stages are passed by default". [^1]
  - the jobs set their own report path to
    `KNAPSACK_REPORT_PATH=knapsack/${CI_PROJECT_NAME}/${JOB_NAME[0]}_node_${CI_NODE_INDEX}_${CI_NODE_TOTAL}_report.json`.
  - if knapsack is doing its job, test files that are run should be listed under
    `Report specs`, not under `Leftover specs`.
1. The `update-knapsack` job takes all the
  `knapsack/${CI_PROJECT_NAME}/${JOB_NAME[0]}_node_${CI_NODE_INDEX}_${CI_NODE_TOTAL}_report.json`
  files from the `rspec x y` jobs and merge them all together into a single
  `knapsack/${CI_PROJECT_NAME}/rspec_report-master.json` file that is then
  uploaded to S3.

After that, the next pipeline will use the up-to-date
`knapsack/${CI_PROJECT_NAME}/rspec_report-master.json` file. The same strategy
is used for Spinach tests as well.

### Monitoring

The GitLab test suite is [monitored] for the `master` branch, and any branch
that includes `rspec-profile` in their name.

A [public dashboard] is available for everyone to see. Feel free to look at the
slowest test files and try to improve them.

[monitored]: ../performance.md#rspec-profiling
[public dashboard]: https://redash.gitlab.com/public/dashboards/l1WhHXaxrCWM5Ai9D7YDqHKehq6OU3bx5gssaiWe?org_slug=default

## CI setup

- On CE and EE, the test suite runs both PostgreSQL and MySQL.
- Rails logging to `log/test.log` is disabled by default in CI [for
  performance reasons][logging]. To override this setting, provide the
  `RAILS_ENABLE_TEST_LOG` environment variable.

[logging]: https://jtway.co/speed-up-your-rails-test-suite-by-6-in-1-line-13fedb869ec4

---

[Return to Testing documentation](index.md)
