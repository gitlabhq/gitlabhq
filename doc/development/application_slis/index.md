---
stage: Platforms
group: Scalability
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Application Service Level Indicators (SLIs)

> [Introduced](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/525) in GitLab 14.4

It is possible to define [Service Level Indicators
(SLIs)](https://en.wikipedia.org/wiki/Service_level_indicator)
directly in the Ruby codebase. This keeps the definition of operations
and their success close to the implementation and allows the people
building features to easily define how these features should be
monitored.

Defining an SLI causes 2
[Prometheus
counters](https://prometheus.io/docs/concepts/metric_types/#counter)
to be emitted from the rails application:

- `gitlab_sli:<sli name>:total`: incremented for each operation.
- `gitlab_sli:<sli_name>:success_total`: incremented for successful
  operations.

## Existing SLIs

1. [`rails_request_apdex`](rails_request_apdex.md)

## Defining a new SLI

An SLI can be defined using the `Gitlab::Metrics::Sli` class.

Before the first scrape, it is important to have [initialized the SLI
with all possible
label-combinations](https://prometheus.io/docs/practices/instrumentation/#avoid-missing-metrics). This
avoid confusing results when using these counters in calculations.

To initialize an SLI, use the `.inilialize_sli` class method, for
example:

```ruby
Gitlab::Metrics::Sli.initialize_sli(:received_email, [
  {
    feature_category: :team_planning,
    email_type: :create_issue
  },
  {
    feature_category: :service_desk,
    email_type: :service_desk
  },
  {
    feature_category: :code_review,
    email_type: :create_merge_request
  }
])
```

Metrics must be initialized before they get
scraped for the first time. This could be done at the start time of the
process that will emit them, in which case we need to pay attention
not to increase application's boot time too much. This is preferable
if possible.

Alternatively, if initializing would take too long, this can be done
during the first scrape. We need to make sure we don't do it for every
scrape. This can be done as follows:

```ruby
def initialize_request_slis_if_needed!
  return if Gitlab::Metrics::Sli.initialized?(:rails_request_apdex)
  Gitlab::Metrics::Sli.initialize_sli(:rails_request_apdex, possible_request_labels)
end
```

Also pay attention to do it for the different metrics
endpoints we have. Currently the
[`WebExporter`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/metrics/exporter/web_exporter.rb)
and the
[`HealthController`](https://gitlab.com/gitlab-org/gitlab/blob/master/app/controllers/health_controller.rb)
for Rails and
[`SidekiqExporter`](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/metrics/exporter/sidekiq_exporter.rb)
for Sidekiq.

## Tracking operations for an SLI

Tracking an operation in the newly defined SLI can be done like this:

```ruby
Gitlab::Metrics::Sli[:received_email].increment(
  labels: {
    feature_category: :service_desk,
    email_type: :service_desk
  },
  success: issue_created?
)
```

Calling `#increment` on this SLI will increment the total Prometheus counter

```prometheus
gitlab_sli:received_email:total{ feature_category='service_desk', email_type='service_desk' }
```

If the `success:` argument passed is truthy, then the success counter
will also be incremented:

```prometheus
gitlab_sli:received_email:success_total{ feature_category='service_desk', email_type='service_desk' }
```

## Using the SLI in service monitoring and alerts

When the application is emitting metrics for the new SLI, those need
to be consumed in the service catalog to result in alerts, and be
included in the error budget for stage groups and GitLab.com's overall
availability.

This is currently being worked on in [this
project](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/573). As
part of [this
issue](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1307)
we will update the documentation.

For any question, please don't hesitate to createan issue in [the
Scalability issue
tracker](https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues)
or come find us in
[#g_scalability](https://gitlab.slack.com/archives/CMMF8TKR9) on Slack.
