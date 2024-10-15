---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# CI/CD job log timestamps

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/455582) in GitLab 17.1 [with a flag](../../administration/feature_flags.md) named `parse_ci_job_timestamps`. Disabled by default.
> - Feature flag `parse_ci_job_timestamps` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/464785) in GitLab 17.2.

You can generate a timestamp in the [ISO 8601 format](https://www.iso.org/iso-8601-date-and-time-format.html)
for each line in a CI/CD job log. With job log timestamps, you can identify the duration
of a specific section in the job. By default, job logs do not include a timestamp for each log line.

When timestamps are enabled, the job log uses approximately 10% more storage space.

Prerequisites:

- You must be on GitLab Runner 17.0 or later.

To enable timestamps in job logs, add a `FF_TIMESTAMPS` [CI/CD variable](../runners/configure_runners.md#configure-runner-behavior-with-variables)
to your pipeline and set it to `true`.

For example, [add the variable to your `.gitlab-ci.yml` file](../variables/index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file):

```yaml
variables:
  FF_TIMESTAMPS: true

job:
  script:
    - echo "This job's log has ISO 8601 timestamps!"
```

Here's an example log output with `FF_TIMESTAMPS` enabled:

![Timestamps for each log line](img/ci_log_timestamp_v17_1.png)

To provide feedback on this feature, leave a comment on [issue 463391](https://gitlab.com/gitlab-org/gitlab/-/issues/463391).
