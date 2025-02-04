---
stage: Platforms
group: Scalability
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: GitLab Application Service Level Indicators (SLIs)
---

It is possible to define [Service Level Indicators(SLIs)](https://en.wikipedia.org/wiki/Service_level_indicator)
directly in the Ruby codebase. This keeps the definition of operations
and their success close to the implementation and allows the people
building features to easily define how these features should be
monitored.

## Existing SLIs

1. [`rails_request`](rails_request.md)
1. `global_search_apdex`
1. `global_search_error_rate`
1. `global_search_indexing_apdex`
1. [`sidekiq_execution`](sidekiq_execution.md)

## Defining a new SLI

An SLI can be defined with the `Gitlab::Metrics::Sli::Apdex` or
`Gitlab::Metrics::Sli::ErrorRate` class. When you define an SLI, two
[Prometheus counters](https://prometheus.io/docs/concepts/metric_types/#counter)
are emitted from the Rails application. Both counters work in broadly the same way and contain a total operation count. `Apdex` uses a success rate to calculate a success ratio, and `ErrorRate` uses an error rate to calculate an error ratio.

The following metrics are defined:

- `Gitlab::Metrics::Sli::Apdex.new('foo')` defines:
  - `gitlab_sli_foo_apdex_total` for the total number of measurements.
  - `gitlab_sli_foo_apdex_success_total` for the number of successful
    measurements.
- `Gitlab::Metrics::Sli::ErrorRate.new('foo')` defines:
  - `gitlab_sli_foo_total` for the total number of measurements.
  - `gitlab_sli_foo_error_total` for the number of error
    measurements. Because this metric is an error rate,
    errors are divided by the total number.

As shown in this example, they can share a base name (`foo` in this example). We
recommend this when they refer to the same operation.

You should use `Apdex` to measure the performance of successful operations. You don't have to measure the performance of a failing request because that performance should be tracked with `ErrorRate`. For example, you can measure whether a request is performing within a specified latency threshold.

You should use `ErrorRate` to measure the rate of unsuccessful operations. For example, you can measure whether a failed request returns an HTTP status greater than or equal to `500`.

Before the first scrape, it is important to have
[initialized the SLI with all possible label-combinations](https://prometheus.io/docs/practices/instrumentation/#avoid-missing-metrics).
This avoid confusing results when using these counters in calculations.

To initialize an SLI, use the `.initialize_sli` class method, for
example:

```ruby
Gitlab::Metrics::Sli::Apdex.initialize_sli(:received_email, [
  {
    feature_category: :team_planning,
    email_type: :create_issue
  },
  {
    feature_category: :service_desk,
    email_type: :service_desk
  },
  {
    feature_category: :code_review_workflow,
    email_type: :create_merge_request
  }
])
```

Metrics must be initialized before they get scraped for the first time.
This currently happens during the `on_master_start` [lifecycle event](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/cluster/lifecycle_events.rb).
Since this delays application readiness until metrics initialization returns, make sure the overhead
this adds is understood and acceptable.

## Tracking operations for an SLI

Tracking an operation in the newly defined SLI can be done like this:

```ruby
Gitlab::Metrics::Sli::Apdex[:received_email].increment(
  labels: {
    feature_category: :service_desk,
    email_type: :service_desk
  },
  success: issue_created?
)
```

Calling `#increment` on this SLI will increment the total Prometheus counter

```prometheus
gitlab_sli:received_email_apdex:total{ feature_category='service_desk', email_type='service_desk' }
```

If the `success:` argument passed is truthy, then the success counter will also
be incremented:

```prometheus
gitlab_sli:received_email_apdex:success_total{ feature_category='service_desk', email_type='service_desk' }
```

For error rate SLIs, the equivalent argument is called `error:`:

```ruby
Gitlab::Metrics::Sli::ErrorRate[:merge].increment(
  labels: {
    merge_type: :fast_forward
  },
  error: !merge_success?
)
```

## Using the SLI in service monitoring and alerts

When the application is emitting metrics for a new SLI, they need
to be consumed from the [metrics catalog](https://gitlab.com/gitlab-com/runbooks/-/tree/master/metrics-catalog)
to result in alerts, and included in the error budget for stage
groups and GitLab.com's overall availability.

Start by adding the new SLI to the
[Application-SLI library](https://gitlab.com/gitlab-com/runbooks/-/blob/d109886dfd5170793eeb8de3d69aafd4a9da78f6/metrics-catalog/gitlab-slis/library.libsonnet#L4).
After that, add the following information:

- `name`: the name of the SLI as defined in code. For example
  `received_email`.
- `significantLabels`: an array of Prometheus labels that belong to the
  metrics. For example: `["email_type"]`. If the significant labels
  for the SLI include `feature_category`, the metrics will also
  feed into the
  [error budgets for stage groups](../stage_group_observability/_index.md#error-budget).
- `featureCategory`: if the SLI applies to a single feature category,
  you can specify it statically through this field to feed the SLI
  into the error budgets for stage groups.
- `description`: a Markdown string explaining the SLI. It will
  be shown on dashboards and alerts.
- `kind`: the kind of indicator. For example `sliDefinition.apdexKind`.

When done, run `make generate` to generate recording rules for
the new SLI. This command creates recordings for all services
emitting these metrics aggregated over `significantLabels`.

Open up a merge request with these changes and request review from a Scalability
team member.

When these changes are merged, and the aggregations in
[Mimir](https://dashboards.gitlab.net/explore?schemaVersion=1&panes=%7B%22m95%22%3A%7B%22datasource%22%3A%22e58c2f51-20f8-4f4b-ad48-2968782ca7d6%22%2C%22queries%22%3A%5B%7B%22refId%22%3A%22A%22%2C%22expr%22%3A%22%22%2C%22range%22%3Atrue%2C%22instant%22%3Atrue%2C%22datasource%22%3A%7B%22type%22%3A%22prometheus%22%2C%22uid%22%3A%22e58c2f51-20f8-4f4b-ad48-2968782ca7d6%22%7D%7D%5D%2C%22range%22%3A%7B%22from%22%3A%22now-6h%22%2C%22to%22%3A%22now%22%7D%7D%7D&orgId=1) recorded, query Mimir to see
the success ratio of the new aggregated metrics. For example:

```prometheus
sum by (environment, stage, type)(application_sli_aggregation:rails_request:apdex:success:rate_1h)
/
sum by (environment, stage, type)(application_sli_aggregation:rails_request:apdex:weight:score_1h)
```

This shows the success ratio, which can guide you to set an
appropriate SLO when adding this SLI to a service.

Then, add the SLI to the appropriate service
catalog file. For example, the [`web` service](https://gitlab.com/gitlab-com/runbooks/-/blob/2b7be37a006c236bd684a4e6a1fbf4c66158292a/metrics-catalog/services/web.jsonnet#L198):

```jsonnet
rails_requests:
  sliLibrary.get('rails_request_apdex')
    .generateServiceLevelIndicator({ job: 'gitlab-rails' })
```

To pass extra selectors and override properties of the SLI, see the
[service monitoring documentation](https://gitlab.com/gitlab-com/runbooks/blob/master/metrics-catalog/README.md).

SLIs with statically defined feature categories can already receive
alerts about the SLI in specified Slack channels. For more information, read the
[alert routing documentation](https://gitlab.com/gitlab-com/runbooks/-/blob/master/docs/uncategorized/alert-routing.md).
In [this project](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/614)
we are extending this so alerts for SLIs with a `feature_category`
label in the source metrics can also be routed.

For any question, don't hesitate to create an issue in
[the Scalability issue tracker](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues)
or come find us in
[#g_scalability](https://gitlab.slack.com/archives/CMMF8TKR9) on Slack.
