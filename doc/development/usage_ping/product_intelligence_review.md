---
stage: Growth
group: Product Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Product Intelligence review guidelines

This page includes introductory material for a
[Product Intelligence](https://about.gitlab.com/handbook/engineering/development/growth/product-intelligence/)
review, and is specific to Product Intelligence reviews. For broader advice and
general best practices for code reviews, refer to our [code review guide](../code_review.md).

## Resources for Product Intelligence reviewers

- [Usage Ping Guide](index.md)
- [Snowplow Guide](../snowplow/index.md)
- [Metrics Dictionary](metrics_dictionary.md)

## Review process

We recommend a Product Intelligence review when an application update touches
Product Intelligence files.

- Changes that touch `usage_data*` files.
- Changes to the Metrics Dictionary including files in:
  - [`config/metrics`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/config/metrics).
  - [`ee/config/metrics`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/config/metrics).
  - [`dictionary.md`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/usage_ping/dictionary.md).
  - [`schema.json`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/schema.json).
- Changes to `tracking` files.
- Changes to Product Intelligence tooling. For example,
  [`Gitlab::UsageMetricDefinitionGenerator`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/generators/gitlab/usage_metric_definition_generator.rb)

### Roles and process

#### The merge request **author** should

- Decide whether a Product Intelligence review is needed.
- If a Product Intelligence review is needed, add the labels
  `~product intelligence` and `~product intelligence::review pending`.
- Assign an
  [engineer](https://gitlab.com/groups/gitlab-org/growth/product-intelligence/engineers/-/group_members?with_inherited_permissions=exclude) from the Product Intelligence team for a review.
- Set the correct attributes in YAML metrics:
  - `product_section`, `product_stage`, `product_group`, `product_category`
  - Provide a clear description of the metric.
- Update the
  [Metrics Dictionary](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/development/usage_ping/dictionary.md) if it is needed.
- Add a changelog [according to guidelines](../changelog.md).

##### When adding or modifying Snowplow events

- For frontend events, when relevant, add a screenshot of the event in
  the [testing tool](../snowplow/index.md#developing-and-testing-snowplow) used.
- For backend events, when relevant, add the output of the Snowplow Micro
  good events `GET http://localhost:9090/micro/good` (it might be a good idea
  to reset with `GET http://localhost:9090/micro/reset` first).

#### The Product Intelligence **reviewer** should

- Perform a first-pass review on the merge request and suggest improvements to the author.
- Approve the MR, and relabel the MR with `~"product intelligence::approved"`.

## Review workload distribution

[Danger bot](../dangerbot.md) adds the list of Product Intelligence changed files
and pings the
[`@gitlab-org/growth/product-intelligence/engineers`](https://gitlab.com/groups/gitlab-org/growth/product-intelligence/engineers/-/group_members?with_inherited_permissions=exclude) group for merge requests
that are not drafts.

Any of the Product Intelligence engineers can be assigned for the Product Intelligence review.

### How to review for Product Intelligence

- Check the [metrics location](index.md#1-naming-and-placing-the-metrics) in
  the Usage Ping JSON payload.
- Add `~database` label and ask for [database review](../database_review.md) for
  metrics that are based on Database.
- For tracking using Redis HLL (HyperLogLog):
  - Check the Redis slot.
  - Check if a [feature flag is needed](index.md#recommendations).
- For tracking with Snowplow:
  - Check that the [event taxonomy](../snowplow/index.md#structured-event-taxonomy) is correct.
  - Check the [usage recommendations](../snowplow/index.md#usage-recommendations).
- Metrics YAML definitions:
  - Check the metric `description`.
  - Check the metrics `key_path`.
  - Check the `product_section`, `product_stage`, `product_group`, `product_category`.
    Read the [stages file](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml).
  - Check the file location. Consider the time frame, and if the file should be under `ee`.
  - Check the tiers.
