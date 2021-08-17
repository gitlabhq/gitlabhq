---
stage: Growth
group: Product Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Develop and test Service Ping

To add a new metric and test Service Ping:

1. [Name and place the metric](#name-and-place-the-metric)
1. [Test counters manually using your Rails console](#test-counters-manually-using-your-rails-console)
1. [Generate the SQL query](#generate-the-sql-query)
1. [Optimize queries with `#database-lab`](#optimize-queries-with-database-lab)
1. [Add the metric definition](#add-the-metric-definition)
1. [Add the metric to the Versions Application](#add-the-metric-to-the-versions-application)
1. [Create a merge request](#create-a-merge-request)
1. [Verify your metric](#verify-your-metric)
1. [Set up and test Service Ping locally](#set-up-and-test-service-ping-locally)

## Name and place the metric

Add the metric in one of the top-level keys:

- `settings`: for settings related metrics.
- `counts_weekly`: for counters that have data for the most recent 7 days.
- `counts_monthly`: for counters that have data for the most recent 28 days.
- `counts`: for counters that have data for all time.

### How to get a metric name suggestion

The metric YAML generator can suggest a metric name for you.
To generate a metric name suggestion, first instrument the metric at the provided `key_path`.
Then, generate the metric's YAML definition and
return to the instrumentation and update it.

1. Add the metric instrumentation to `lib/gitlab/usage_data.rb` inside one
   of the [top-level keys](#name-and-place-the-metric), using any name you choose.
1. Run the [metrics YAML generator](metrics_dictionary.md#metrics-definition-and-validation).
1. Use the metric name suggestion to select a suitable metric name.
1. Update the instrumentation you created in the first step and change the metric name to the suggested name.
1. Update the metric's YAML definition with the correct `key_path`.

## Test counters manually using your Rails console

```ruby
# count
Gitlab::UsageData.count(User.active)
Gitlab::UsageData.count(::Clusters::Cluster.aws_installed.enabled, :cluster_id)

# count distinct
Gitlab::UsageData.distinct_count(::Project, :creator_id)
Gitlab::UsageData.distinct_count(::Note.with_suggestions.where(time_period), :author_id, start: ::User.minimum(:id), finish: ::User.maximum(:id))
```

## Generate the SQL query

Your Rails console returns the generated SQL queries. For example:

```ruby
pry(main)> Gitlab::UsageData.count(User.active)
   (2.6ms)  SELECT "features"."key" FROM "features"
   (15.3ms)  SELECT MIN("users"."id") FROM "users" WHERE ("users"."state" IN ('active')) AND ("users"."user_type" IS NULL OR "users"."user_type" IN (6, 4))
   (2.4ms)  SELECT MAX("users"."id") FROM "users" WHERE ("users"."state" IN ('active')) AND ("users"."user_type" IS NULL OR "users"."user_type" IN (6, 4))
   (1.9ms)  SELECT COUNT("users"."id") FROM "users" WHERE ("users"."state" IN ('active')) AND ("users"."user_type" IS NULL OR "users"."user_type" IN (6, 4)) AND "users"."id" BETWEEN 1 AND 100000
```

## Optimize queries with `#database-lab`

`#database-lab` is a Slack channel that uses a production-sized environment to test your queries.
Paste the SQL query into `#database-lab` to see how the query performs at scale.

- GitLab.com's production database has a 15 second timeout.
- Any single query must stay below the [1 second execution time](../query_performance.md#timing-guidelines-for-queries) with cold caches.
- Add a specialized index on columns involved to reduce the execution time.

To understand the query's execution, we add the following information
to a merge request description:

- For counters that have a `time_period` test, we add information for both:
  - `time_period = {}` for all time periods.
  - `time_period = { created_at: 28.days.ago..Time.current }` for the last 28 days.
- Execution plan and query time before and after optimization.
- Query generated for the index and time.
- Migration output for up and down execution.

We also use `#database-lab` and [explain.depesz.com](https://explain.depesz.com/). For more details, see the [database review guide](../database_review.md#preparation-when-adding-or-modifying-queries).

### Optimization recommendations and examples

- Use specialized indexes. For examples, see these merge requests:
  - [Example 1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/26871)
  - [Example 2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/26445)
- Use defined `start` and `finish`, and simple queries.
  These values can be memoized and reused, as in this [example merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/37155).
- Avoid joins and write the queries as simply as possible,
  as in this [example merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/36316).
- Set a custom `batch_size` for `distinct_count`, as in this [example merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/38000).

## Add the metric definition

See the [Metrics Dictionary guide](metrics_dictionary.md) for more information.

## Add the metric to the Versions Application

Check if the new metric must be added to the Versions Application. See the `usage_data` [schema](https://gitlab.com/gitlab-services/version-gitlab-com/-/blob/master/db/schema.rb#L147) and Service Data [parameters accepted](https://gitlab.com/gitlab-services/version-gitlab-com/-/blob/master/app/services/usage_ping.rb). Any metrics added under the `counts` key are saved in the `stats` column.

## Create a merge request

Create a merge request for the new Service Ping metric, and do the following:

- Add the `feature` label to the merge request. A metric is a user-facing change and is part of expanding the Service Ping feature.
- Add a changelog entry that complies with the [changelog entries guide](../changelog.md).
- Ask for a Product Intelligence review.
  On GitLab.com, we have DangerBot set up to monitor Product Intelligence related files and recommend a [Product Intelligence review](review_guidelines.md).

## Verify your metric

On GitLab.com, the Product Intelligence team regularly [monitors Service Ping](https://gitlab.com/groups/gitlab-org/-/epics/6000).
They may alert you that your metrics need further optimization to run quicker and with greater success.

The Service Ping JSON payload for GitLab.com is shared in the
[#g_product_intelligence](https://gitlab.slack.com/archives/CL3A7GFPF) Slack channel every week.

You may also use the [Service Ping QA dashboard](https://app.periscopedata.com/app/gitlab/632033/Usage-Ping-QA) to check how well your metric performs.
The dashboard allows filtering by GitLab version, by "Self-managed" and "SaaS", and shows you how many failures have occurred for each metric. Whenever you notice a high failure rate, you can re-optimize your metric.

## Set up and test Service Ping locally

To set up Service Ping locally, you must:

1. [Set up local repositories](#set-up-local-repositories).
1. [Test local setup](#test-local-setup).
1. (Optional) [Test Prometheus-based Service Ping](#test-prometheus-based-service-ping).

### Set up local repositories

1. Clone and start [GitLab](https://gitlab.com/gitlab-org/gitlab-development-kit).
1. Clone and start [Versions Application](https://gitlab.com/gitlab-services/version-gitlab-com).
   Make sure you run `docker-compose up` to start a PostgreSQL and Redis instance.
1. Point GitLab to the Versions Application endpoint instead of the default endpoint:
   1. Open [service_ping/submit_service.rb](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/services/service_ping/submit_service.rb#L5) in your local and modified `PRODUCTION_URL`.
   1. Set it to the local Versions Application URL: `http://localhost:3000/usage_data`.

### Test local setup

1. Using the `gitlab` Rails console, manually trigger Service Ping:

   ```ruby
   ServicePing::SubmitService.new.execute
   ```

1. Use the `versions` Rails console to check the Service Ping was successfully received,
   parsed, and stored in the Versions database:

   ```ruby
   UsageData.last
   ```

## Test Prometheus-based Service Ping

If the data submitted includes metrics [queried from Prometheus](index.md#prometheus-queries)
you want to inspect and verify, you must:

- Ensure that a Prometheus server is running locally.
- Ensure the respective GitLab components are exporting metrics to the Prometheus server.

If you do not need to test data coming from Prometheus, no further action
is necessary. Service Ping should degrade gracefully in the absence of a running Prometheus server.

Three kinds of components may export data to Prometheus, and are included in Service Ping:

- [`node_exporter`](https://github.com/prometheus/node_exporter): Exports node metrics
  from the host machine.
- [`gitlab-exporter`](https://gitlab.com/gitlab-org/gitlab-exporter): Exports process metrics
  from various GitLab components.
- Other various GitLab services, such as Sidekiq and the Rails server, which export their own metrics.

### Test with an Omnibus container

This is the recommended approach to test Prometheus-based Service Ping.

To verify your change, build a new Omnibus image from your code branch using CI/CD, download the image,
and run a local container instance:

1. From your merge request, select the `qa` stage, then trigger the `package-and-qa` job. This job triggers an Omnibus
   build in a [downstream pipeline of the `omnibus-gitlab-mirror` project](https://gitlab.com/gitlab-org/build/omnibus-gitlab-mirror/-/pipelines).
1. In the downstream pipeline, wait for the `gitlab-docker` job to finish.
1. Open the job logs and locate the full container name including the version. It takes the following form: `registry.gitlab.com/gitlab-org/build/omnibus-gitlab-mirror/gitlab-ee:<VERSION>`.
1. On your local machine, make sure you are signed in to the GitLab Docker registry. You can find the instructions for this in
   [Authenticate to the GitLab Container Registry](../../user/packages/container_registry/index.md#authenticate-with-the-container-registry).
1. Once signed in, download the new image by using `docker pull registry.gitlab.com/gitlab-org/build/omnibus-gitlab-mirror/gitlab-ee:<VERSION>`
1. For more information about working with and running Omnibus GitLab containers in Docker, refer to [GitLab Docker images](https://docs.gitlab.com/omnibus/docker/README.html) in the Omnibus documentation.

### Test with GitLab development toolkits

This is the less recommended approach, because it comes with a number of difficulties when emulating a real GitLab deployment.

The [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit) is not set up to run a Prometheus server or `node_exporter` alongside other GitLab components. If you would
like to do so, [Monitoring the GDK with Prometheus](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/howto/prometheus/index.md#monitoring-the-gdk-with-prometheus) is a good start.

The [GCK](https://gitlab.com/gitlab-org/gitlab-compose-kit) has limited support for testing Prometheus based Service Ping.
By default, it comes with a fully configured Prometheus service that is set up to scrape a number of components.
However, it has the following limitations:

- It does not run a `gitlab-exporter` instance, so several `process_*` metrics from services such as Gitaly may be missing.
- While it runs a `node_exporter`, `docker-compose` services emulate hosts, meaning that it normally reports itself as not associated
  with any of the other running services. That is not how node metrics are reported in a production setup, where `node_exporter`
  always runs as a process alongside other GitLab components on any given node. For Service Ping, none of the node data would therefore
  appear to be associated to any of the services running, because they all appear to be running on different hosts. To alleviate this problem, the `node_exporter` in GCK was arbitrarily "assigned" to the `web` service, meaning only for this service `node_*` metrics appears in Service Ping.
