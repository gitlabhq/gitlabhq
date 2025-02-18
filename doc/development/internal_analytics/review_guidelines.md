---
stage: Monitor
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Internal Analytics review guidelines
---

This page includes introductory material for an
[Analytics Instrumentation](https://handbook.gitlab.com/handbook/engineering/development/analytics/analytics-instrumentation/)
review. For broader advice and general best practices for code reviews, refer to our [code review guide](../code_review.md).

## Review process

We mandate an Analytics Instrumentation review when a merge request (MR) touches or uses internal analytics code.
This includes but is not limited to:

- Metrics, for example:
  - files in [`config/metrics`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/config/metrics).
  - files in [`ee/config/metrics`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/config/metrics).
  - [`schema.json`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/schema.json).
- Internal events, for example files in [`config/events`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/config/events).
- Analytics Instrumentation tooling, for example [`Internal events CLI`](https://gitlab.com/gitlab-org/gitlab/blob/master/scripts/internal_events/cli.rb).

In most cases, an Analytics Instrumentation review is automatically added, but it can also be requested manually if the automations miss the relevant change.

### Roles and process

#### The merge request **author** should

- Decide whether a Analytics Instrumentation review is needed. You can skip the Analytics Instrumentation
  review and remove the labels if the changes are not related to the Analytics Instrumentation domain.
- If an Analytics Instrumentation review is needed and was not assigned automatically, add the labels
  `~analytics instrumentation` and `~analytics instrumentation::review pending`.
- If a change to an event is a part of the MR:
  - Check that the events are firing locally using one of the [testing tools](internal_event_instrumentation/local_setup_and_debugging.md) available.
- If a change to a metric is a part of the MR:
  - Make sure that the new metric is available and reporting data in the Service Ping payload, by running: `require_relative 'spec/support/helpers/service_ping_helpers.rb'; ServicePingHelpers.get_current_usage_metric_value(key_path)` with `key_path` substituted by the new metric's `key_path`.
- Use reviewer roulette to assign an [Analytics Instrumentation reviewer](https://gitlab-org.gitlab.io/gitlab-roulette/?hourFormat24=true&visible=reviewer%7Canalytics+instrumentation) who is not the author.
- Assign any other reviews as appropriate.
- `~analytics instrumentation` review does not require a maintainer review.

#### The Analytics Instrumentation **reviewer** should

- Perform a first-pass review on the merge request and suggest improvements to the author.
- Make sure that no deprecated analytics methods are used.
- If a change to an event is a part of the review:
  - Check that the event(s) being fired have corresponding definition files.
  - Check that the [event definition file](internal_event_instrumentation/event_definition_guide.md) is correct.
- If a change to a metric is a part of the review:
  - Add the `~database` label and ask for a [database review](../database_review.md) for
    metrics that are based on Database.
  - For a metric's YAML definition:
    - Check the metric's `description`.
    - Check the metric's `key_path`.
    - Check the `product_group` field.
      They should correspond to the [stages file](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml).
    - Check the file location. Consider the time frame, and if the file should be under `ee`.
    - Check the tiers.
  - If a metric was changed or removed: Make sure the MR author notified the Customer Success Ops team (`@csops-team`), Analytics Engineers (`@gitlab-data/analytics-engineers`), and Product Analysts (`@gitlab-data/product-analysts`) by `@` mentioning those groups in a comment on the issue for the MR and all of these groups have acknowledged the removal.
- If a change to the Internal Events CLI is a part of the review:
  - Check the changes follow the [CLI style guide](cli_contribution_guidelines.md).
  - Run the CLI & check the UX of the changes:
    - Is the content easy to skim?
    - Would this content make sense to people outside the team?
    - Is this information necessary? Helpful?
    - What reservations would I have if I'd never gone through this flow before?
    - Is the meaning or effect of every input clear?
    - If we describe edge cases or caveats, are there instructions to validate whether the user needs to worry about it?
- Approve the MR, and relabel the MR with `~"analytics instrumentation::approved"`.
