---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Test balancing API
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/607450) in GitLab 19.4 [with a flag](../administration/feature_flags/_index.md) named `parallel_test_balancing`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

Use this API to distribute tests across the nodes of a [`parallel:`](../ci/yaml/_index.md#parallel)
CI/CD job based on test durations, so that every node finishes at roughly the same time.

A test split is a unit of work to distribute across nodes.
When you split by file, each test split is a test file.
Nodes seed a shared pending pool with their static test split, then repeatedly request
duration-budgeted batches of test splits as they finish. Faster nodes absorb more work. When a
node is retried, it receives the exact set of test splits it was originally assigned.

Both endpoints:

- Must be called from the running parallel job, authenticated with a
  [CI/CD job token](../ci/jobs/ci_job_token.md) (`CI_JOB_TOKEN`).
- Return `422 Unprocessable Entity` when the calling job does not use the `parallel:` keyword.
- Return `422 Unprocessable Entity` for pipelines created more than 30 days ago, because test
  balancing data, including retries, is retained for 30 days from pipeline creation.

## Initialize test balancing for a parallel job

Seeds the job group's shared pending pool with the caller's static test split and claims a
first batch of test splits. If the node already has claimed test splits (for example, when a job is
retried or recovered from a crash), the previously claimed test set is returned unchanged
and the `test_splits` parameter is ignored.

This endpoint returns `422 Unprocessable Entity` when the seed would push the job group's
shared pool past 50,000 test splits.

```plaintext
POST /job/test_balancing/initialize
```

Supported attributes:

| Attribute                         | Type            | Required | Description |
|-----------------------------------|-----------------|----------|-------------|
| `test_splits`                     | array of hashes | Yes      | The test splits of the static split assigned to this node. Maximum 1,000 entries. |
| `test_splits[].path`              | string          | Yes      | The path of the test split, relative to the repository root. Maximum 1024 characters. |
| `test_splits[].expected_duration` | float           | No       | The expected duration of the test split, in seconds. Defaults to 300 when not given. |

If successful, returns [`201 Created`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                         | Type   | Description |
|-----------------------------------|--------|-------------|
| `mode`                            | string | `seed` when the pool was seeded and a first batch claimed, or `retry` when a previously claimed test set was replayed. |
| `test_splits`                     | array  | The test splits the node should run. On `retry`, the full original test set. |
| `test_splits[].path`              | string | The path of the test split, relative to the repository root. |
| `test_splits[].expected_duration` | float  | The expected duration at seed time, in seconds. Defaults to 300 when not given. |

Example request:

```shell
curl --request POST \
  --header "JOB-TOKEN: $CI_JOB_TOKEN" \
  --header "Content-Type: application/json" \
  --data '{"test_splits": [{"path": "spec/models/user_spec.rb", "expected_duration": 12.5}]}' \
  --url "https://gitlab.example.com/api/v4/job/test_balancing/initialize"
```

Example response:

```json
{
  "mode": "seed",
  "test_splits": [
    {
      "path": "spec/models/user_spec.rb",
      "expected_duration": 12.5
    }
  ]
}
```

## Request the next batch of tests

Atomically claims a duration-budgeted batch of pending test splits for the calling node, slowest
first. An empty `test_splits` array means the queue is drained and the node should stop
requesting batches.

The server chooses the batch size automatically based on the total remaining expected duration in
the shared pool. When a large amount of duration remains, the server returns larger batches to
reduce the number of requests. As the pool drains, the server returns smaller batches so that work
stays balanced across nodes.

```plaintext
POST /job/test_balancing/request
```

This endpoint does not take any attributes.

If successful, returns [`201 Created`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                         | Type   | Description |
|-----------------------------------|--------|-------------|
| `test_splits`                     | array  | The test splits the node should run. Empty when the queue is drained. |
| `test_splits[].path`              | string | The path of the test split, relative to the repository root. |
| `test_splits[].expected_duration` | float  | The expected duration at seed time, in seconds. Defaults to 300 when not given. |

Example request:

```shell
curl --request POST \
  --header "JOB-TOKEN: $CI_JOB_TOKEN" \
  --url "https://gitlab.example.com/api/v4/job/test_balancing/request"
```

Example response:

```json
{
  "test_splits": [
    {
      "path": "spec/features/login_spec.rb",
      "expected_duration": 210.4
    }
  ]
}
```
