---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Logs on GitLab.com
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

Information about logs on GitLab.com.

## How GitLab.com creates logs

[Fluentd](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#fluentd)
parses GitLab logs, then sends them to:

- [Stackdriver Logging](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#stackdriver),
  which stores logs long-term in Google Cold Storage (GCS).
- [Cloud Pub/Sub](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#cloud-pubsub),
  which forwards logs to an [Elastic cluster](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#elastic)
  using [`pubsubbeat`](https://gitlab.com/gitlab-com/runbooks/tree/master/logging/doc#pubsubbeat-vms).

For more information, see GitLab runbooks for:

- A [detailed list of what gets logged](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/logging#what-are-we-logging).
- Current [log retention policies](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/logging#retention).
- A [diagram of GitLab logging infrastructure](https://gitlab.com/gitlab-com/runbooks/-/tree/master/docs/logging#logging-infrastructure-overview).

## Erase CI/CD job logs

By default, GitLab does not expire CI/CD job logs. Job logs are retained indefinitely,
and can't be configured on GitLab.com to expire. You can erase job logs by either:

- [Using the Jobs API](../../api/jobs.md#erase-a-job).
- [Deleting the pipeline](../../ci/pipelines/_index.md#delete-a-pipeline) the job belongs to.
