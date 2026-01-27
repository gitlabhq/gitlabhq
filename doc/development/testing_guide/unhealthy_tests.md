---
stage: none
group: unassigned
info: 'See the Technical Writers assigned to Development Guidelines: https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-development-guidelines'
description: GitLab development guidelines - Unhealthy tests.
title: Unhealthy tests
---

## Flaky tests

This page provides technical reference for understanding and debugging flaky tests in GitLab. For process information about flaky test management, monitoring, and best practices, see the [Flaky Tests handbook page](https://handbook.gitlab.com/handbook/engineering/testing/flaky-tests/).

### What's a flaky test?

It's a test that sometimes fails, but if you retry it enough times, it passes,
eventually.

### How to reproduce a flaky test locally?

1. Reproduce the failure locally
   - Find RSpec `seed` from the CI job log
   - OR Run `while :; do bin/rspec <spec> || break; done` in a loop to find a `seed`
1. Reduce the examples by bisecting the spec failure with
   `bin/rspec --seed <previously found> --require ./config/initializers/macos.rb --bisect <spec>`
1. Look at the remaining examples and watch for state leakage
   - For example, updating records created with `let_it_be` is a common source of problems
1. Once fixed, rerun the specs with `seed`
1. Run `scripts/rspec_check_order_dependence` to ensure the spec can be run in [random order](best_practices.md#test-order)
1. Run `while :; do bin/rspec <spec> || break; done` in a loop again (and grab lunch) to verify it's no longer flaky

### Quarantined tests

When a flaky test is blocking development on `master`, it should be quarantined to prevent impacting other developers.
The [Test Quarantine Process handbook page](https://handbook.gitlab.com/handbook/engineering/testing/quarantine-process/)
provides comprehensive guidance on the quarantine process, including:

- When to use the fast or long-term quarantine process
- Timeline expectations and ownership responsibilities
- How to remove tests from quarantine
- How quarantine ownership and escalation procedures work

For immediate quarantine needs, use
the [fast quarantine process](https://gitlab.com/gitlab-org/quality/engineering-productivity/fast-quarantine/) for rapid
merging. For implementation details on how to quarantine tests in your codebase, refer to the handbook page.

### Automatic retries and flaky tests detection

On our CI, we use [`RSpec::Retry`](https://github.com/NoRedInk/rspec-retry) to automatically retry a failing example a few
times (see [`spec/spec_helper.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/spec/spec_helper.rb) for the precise retries count).

For more information, see [Automatic retry of failing tests in a separate process](../pipelines/_index.md#automatic-retry-of-failing-tests).

### What are the potential cause for a test to be flaky?

<details>
<summary><strong>State leak</strong> - <code>flaky-test::state leak</code></summary>

**Description**: Data state has leaked from a previous test. The actual cause is probably not the flaky test here.

**Difficulty to reproduce**: Moderate. Usually, running the same spec files until the one that's failing reproduces the problem.

**Resolution**: Fix the previous tests and/or places where the test data or environment is modified, so that
it's reset to a pristine test after each test.

**Examples**:

- [Example 1](https://gitlab.com/gitlab-org/gitlab/-/issues/402915): State leakage can result from
  data records created with `let_it_be` shared between test examples, while some test modifies the model
  either deliberately or unwillingly causing out-of-sync data in test examples. This can result in `PG::QueryCanceled: ERROR` in the subsequent test examples or retries.
  For more information about state leakages and resolution options, see [GitLab testing best practices](best_practices.md#lets-talk-about-let).
- [Example 2](https://gitlab.com/gitlab-org/gitlab/-/issues/378414#note_1142026988): A migration
  test might roll-back the database, perform its testing, and then roll-up the database in an
  inconsistent state, so that following tests might not know about certain columns.
- [Example 3](https://gitlab.com/gitlab-org/gitlab/-/issues/368500): A test modifies data that is
  used by a following test.
- [Example 4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/103434#note_1172316521): A test for a database query passes in a fresh database, but in a
  CI/CD pipeline where the database is used to process previous test sequences, the test fails. This likely
  means that the query itself needs to be updated to work in a non-clean database.
- [Example 5](https://gitlab.com/gitlab-org/gitlab/-/issues/416663#note_1457867234): Unrelated database connections
  in asynchronous requests checked back in, causing the tests to accidentally
  use these unrelated database connections. The failure was resolved in this
  [merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125742).
- [Example 6](https://gitlab.com/gitlab-org/gitlab/-/issues/418757#note_1502138269): The maximum time to live
  for a database connection causes these connections to be disconnected, which
  in turn causes tests that rely on the transactions on these connections to
  in turn causes tests that rely on the transactions on these connections to
  fail. The issue was fixed in this [merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128567).
- [Example 7](https://gitlab.com/gitlab-org/quality/engineering-productivity/master-broken-incidents/-/issues/3389#note_1534827164):
  A TCP socket used in a test was not closed before the next test, which also used
  the same port with another TCP socket.
- [Example 8](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/179302#note_2324238692): A `let_it_be` depended on a stub defined in a `before` block. `let_it_be` executes during `before(:all)`, so the stub was not yet set. This exposed the tests to the actual method call, which happened to use a method cache.

</details>

<details>
<summary><strong>Dataset-specific</strong> - <code>flaky-test::dataset-specific</code></summary>

**Description**: The test assumes the dataset is in a particular (usually limited) state or order, which
might not be true depending on when the test run during the test suite.

**Difficulty to reproduce**: Moderate, as the amount of data needed to reproduce the issue might be
difficult to achieve locally. Ordering issues are easier to reproduce by repeatedly running the tests several times.

**Resolution**:

- Fix the test to not assume that the dataset is in a particular state, don't hardcode IDs.
- Loosen the assertion if the test shouldn't care about ordering but only on the elements.
- Fix the test by specifying a deterministic ordering.
- Fix the app code by specifying a deterministic ordering.

**Examples**:

- [Example 1](https://gitlab.com/gitlab-org/gitlab/-/issues/378381): The database is recreated when
  any table has more than 500 columns. It could pass in the merge request, but fail later in
  `master` if the order of tests changes.
- [Example 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91016/diffs): A test asserts
  that trying to find a record with a nonexistent ID returns an error message. The test uses an
  hardcoded ID that's supposed to not exist (for example, `42`). If the test is run early in the test
  suite, it might pass as not enough records were created before it, but as soon as it would run
  later in the suite, there could be a record that actually has the ID `42`, hence the test would
  start to fail.
- [Example 3](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10148/diffs): Without
  specifying `ORDER BY`, database is not given deterministic ordering, or data race can happen
  in the tests.
- [Example 4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106936/diffs).

</details>

<details>
<summary><strong>Too Many SQL queries</strong> - <code>flaky-test::too-many-sql-queries</code></summary>

**Description**: SQL Query limit has reached triggering `Gitlab::QueryLimiting::Transaction::ThresholdExceededError`.

**Difficulty to reproduce**: Moderate, this failure may depend on the state of query cache which can be impacted by order of specs.

**Resolution**: See [query count limits docs](../database/query_count_limits.md#solving-failing-tests).

</details>

<details>
<summary><strong>Random input</strong> - <code>flaky-test::random input</code></summary>

**Description**: The test use random values, that sometimes match the expectations, and sometimes not.

**Difficulty to reproduce**: Easy, as the test can be modified locally to use the "random value"
used at the time the test failed

**Resolution**: Once the problem is reproduced, it should be easy to debug and fix either the test
or the app.

**Examples**:

- [Example 1](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/20121): The test isn't robust enough to handle a specific data, that only appears sporadically since the data input is random.

</details>

<details>
<summary><strong>Unreliable DOM Selector</strong> - <code>flaky-test::unreliable dom selector</code></summary>

**Description**: The DOM selector used in the test is unreliable.

**Difficulty to reproduce**: Moderate to difficult. Depending on whether the DOM selector is duplicated, or appears after a delay etc.
Adding a delay in API or controller could help reproducing the issue.

**Resolution**: It really depends on the problem here. It could be to wait for requests to finish, to scroll down the page etc.

**Examples**:

- [Example 1](https://gitlab.com/gitlab-org/gitlab/-/issues/338341): A non-unique CSS selector
  matching more than one element, or a non-waiting selector method that does not allow rendering
  time before throwing an `element not found` error.
- [Example 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101728/diffs): A CSS selector
  only appears after a GraphQL requests has finished, and the UI has updated.
- [Example 3](https://gitlab.com/gitlab-org/gitlab/-/issues/408215): A false-positive test, Capybara immediately returns true after
  page visit and page is not fully loaded, or if the element is not detectable by webdriver (such as being rendered outside the viewport or behind other elements).

</details>

<details>
<summary><strong>Datetime-sensitive</strong> - <code>flaky-test::datetime-sensitive</code></summary>

**Description**: The test is assuming a specific date or time.

**Difficulty to reproduce**: Easy to moderate, depending on whether the test consistently fails after a certain date, or only fails at a given time or date.

**Resolution**: Freezing the time is usually a good solution.

**Examples**:

- [Example 1](https://gitlab.com/gitlab-org/gitlab/-/issues/118612): A test that breaks after some time passed.
- [Example 2](https://gitlab.com/gitlab-org/gitlab/-/issues/403332): A test that breaks in the last day of the month.

</details>

<details>
<summary><strong>Unstable infrastructure</strong> - <code>flaky-test::unstable infrastructure</code></summary>

**Description**: The test fails from time to time due to infrastructure issues.

**Difficulty to reproduce**: Hard. It's really hard to reproduce CI infrastructure issues. It might
be possible by using containers locally.

**Resolution**: Starting a conversation with the Infrastructure department in a dedicated issue is
usually a good idea.

**Examples**:

- [Example 1](https://gitlab.com/gitlab-org/gitlab/-/issues/363214): The runner is under heavy load at this time.
- [Example 2](https://gitlab.com/gitlab-org/gitlab/-/issues/360559): The runner is having networking issues, making a job failing early

</details>

<details>
<summary><strong>Improper Synchronization</strong> - <code>flaky-test::improper synchronization</code></summary>

**Description**: A flaky test issue arising from timing-related factors, such as delays, eventual consistency, asynchronous operations, or race conditions.
These issues may stem from shortcomings in the test logic, the system under test, or their interaction.
While tests can sometimes address these issues through improved synchronization, they may also reveal underlying system bugs that require resolution.

**Difficulty to reproduce**: Moderate. It can be reproduced, for example, in feature tests by attempting to reference an
element on a page that is not yet rendered, or in unit tests by failing to wait for an asynchronous operation to complete.

**Resolution**: In the end-to-end test suite, using [an eventually matcher](end_to_end/best_practices/_index.md#use-eventually_-matchers-for-expectations-that-require-waiting).

**Examples**:

- [Example 1](https://gitlab.com/gitlab-org/gitlab/-/issues/502844): Text was not appearing on a page in time.
- [Example 2](https://gitlab.com/gitlab-org/gitlab/-/issues/496393): Text was not appearing on a page in time.

</details>

### Additional debugging techniques

#### Split the test file

It could help to split the large RSpec files in multiple files in order to narrow down the context and identify the problematic tests.

#### Recreate job failure in CI by forcing the job to run the same set of test files

Reproducing a job failure in CI always helps with troubleshooting why and how a test fails. This require us running the same test files with the same spec order. Since we use Knapsack to distribute tests across parallelized jobs, and files can be distributed differently between two pipelines, we can hardcode this job distribution through the following steps:

1. Find a job that you want to reproduce, identify the commit that it ran against, set your local `gitlab-org/gitlab` branch to the same commit to ensure we are running with the same copy of the project.
1. In the job log, locate the list of spec files that were distributed by Knapsack - you can search for `Running command: bundle exec rspec`, the last argument of this command should contain a list of filenames. Copy this list.
1. Go to `tooling/lib/tooling/parallel_rspec_runner.rb` where the test file distribution happens. Have a look at [this merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137924/diffs) as an example, store the file list you copied from step 2 into a `TEST_FILES` constant and have RSpec run this list by updating the `rspec_command` method as done in the example MR.
1. Skip the tests in `spec/tooling/lib/tooling/parallel_rspec_runner_spec.rb` so it doesn't cause your pipeline to fail early.
1. Since we want to force the pipeline to run against a specific version, we do not want to run a merged results pipeline. We can introduce a merge conflict into the MR to achieve this.
1. To preserve spec ordering, update the `spec/support/rspec_order.rb` file by hard coding `Kernel.srand` with the value shown in the originally failing job, as done in [merge request 128428](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128428/diffs#32f6fa4961481518204e227252552dba7483c3b0_62_62). You can find the `srand` value in the job log by searching `Randomized with seed` which is followed by this value.

#### Reproduce order-dependent flaky tests

To identify ordering issues in a single file read about
[how to reproduce a flaky test locally](#how-to-reproduce-a-flaky-test-locally).

Some flaky tests can fail depending on the order they run with other tests. For example:

- <https://gitlab.com/gitlab-org/gitlab/-/issues/327668>

To identify the ordering issues across different files, you can use `scripts/rspec_bisect_flaky`,
which would give us the minimal test combination to reproduce the failure:

1. First obtain the list of specs that ran before the flaky test. You can search
   for the list under `Knapsack node specs:` in the CI job output log.
1. Save the list of specs as a file, and run:

   ```shell
   cat knapsack_specs.txt | xargs scripts/rspec_bisect_flaky
   ```

If there is an order-dependency issue, the script above will print the minimal
reproduction.

### Metrics & Tracking

- [Flaky Tests Failure Overview](https://dashboards.devex.gitlab.net/d/ddjwrqc/flaky-tests-overview?orgId=1&from=now-14d&to=now&timezone=browser&var-project=gitlab-org%2Fgitlab&var-run_type=$__all&var-pipeline_type=merge_request_pipeline) (internal)
- [Test File Failure Overview](https://dashboards.devex.gitlab.net/d/63bbf393-7426-403b-a4ec-1ej4280efb6b/test-file-failure-overview?orgId=1&from=now-14d&to=now&timezone=browser&var-project=gitlab-org%2Fgitlab&var-run_type=$__all&var-pipeline_type=merge_request_pipeline&var-file_path=qa%2Fspecs%2Ffeatures%2Fbrowser_ui%2F3_create%2Fmerge_request%2Fcherry_pick%2Fcherry_pick_commit_spec.rb&var-test_location=$__all&var-exception_class=$__all) (internal)

## Slow tests

### Top slow tests

We collect information about tests duration in ClickHouse database. The data is visualized using following [Grafana dashboard](https://dashboards.devex.gitlab.net/d/acv8mwl/test-file-runtime-overview).

In this [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/375983), we defined thresholds for tests duration that can act as a guide.

For tests that are above the thresholds, we automatically report slowness occurrences in [Test issues](https://gitlab.com/gitlab-org/gitlab/-/issues/?sort=created_date&state=opened&label_name%5B%5D=rspec%3Aslow%20test&first_page_size=100) so that groups can improve them.

For tests that are slow for a legitimate reason and to skip issue creation, add `allowed_to_be_slow: true`.

|    Date    | Feature tests | Controllers and Requests tests | Unit  |     Other     | Method |
|:----------:|:-------------:|:------------------------------:|:-----:|:-------------:|:------:|
| 2023-02-15 | 67.42 seconds |         44.66 seconds          |   -   | 76.86 seconds | Top slow test eliminating the maximum |
| 2023-06-15 | 50.13 seconds |         19.20 seconds          | 27.12 | 45.40 seconds | Avg for top 100 slow tests |

---

[Return to Testing documentation](_index.md)
