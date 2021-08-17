---
stage: Growth
group: Product Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Service Ping review guidelines

This page includes introductory material for a
[Product Intelligence](https://about.gitlab.com/handbook/engineering/development/growth/product-intelligence/)
review, and is specific to Service Ping related reviews. For broader advice and
general best practices for code reviews, refer to our [code review guide](../code_review.md).

## Resources for reviewers

- [Service Ping Guide](index.md)
- [Metrics Dictionary](https://gitlab-org.gitlab.io/growth/product-intelligence/metric-dictionary)

## Review process

We recommend a Product Intelligence review when a merge request (MR) touches
any of the following Service Ping files:

- `usage_data*` files.
- The Metrics Dictionary, including files in:
  - [`config/metrics`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/config/metrics).
  - [`ee/config/metrics`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/config/metrics).
  - [`schema.json`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/schema.json).
- Product Intelligence tooling. For example,
  [`Gitlab::UsageMetricDefinitionGenerator`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/generators/gitlab/usage_metric_definition_generator.rb)

### Roles and process

#### The merge request **author** should

- Decide whether a Product Intelligence review is needed. You can skip the Product Intelligence
review and remove the labels if the changes are not related to the Product Intelligence domain and
are regular backend changes.
- If a Product Intelligence review is needed, add the labels
  `~product intelligence` and `~product intelligence::review pending`.
- For merge requests authored by Product Intelligence team members:
  - Assign both the `~backend` and `~product intelligence` reviews to another Product Intelligence team member.
  - Assign the maintainer review to someone outside of the Product Intelligence group.
- Assign an
  [engineer](https://gitlab.com/groups/gitlab-org/growth/product-intelligence/engineers/-/group_members?with_inherited_permissions=exclude) from the Product Intelligence team for a review.
- Set the correct attributes in the metric's YAML definition:
  - `product_section`, `product_stage`, `product_group`, `product_category`
  - Provide a clear description of the metric.
- Add a changelog [according to guidelines](../changelog.md).

#### The Product Intelligence **reviewer** should

- Perform a first-pass review on the merge request and suggest improvements to the author.
- Check the [metrics location](implement.md#name-and-place-the-metric) in
  the Service Ping JSON payload.
- Suggest that the author checks the [naming suggestion](implement.md#how-to-get-a-metric-name-suggestion) while
  generating the metric's YAML definition.
- Add the `~database` label and ask for a [database review](../database_review.md) for
  metrics that are based on Database.
- For tracking using Redis HLL (HyperLogLog):
  - Check the Redis slot.
  - Check if a [feature flag is needed](index.md#recommendations).
- For a metric's YAML definition:
  - Check the metric's `description`.
  - Check the metric's `key_path`.
  - Check the `product_section`, `product_stage`, `product_group`, and `product_category` fields.
    Read the [stages file](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml).
  - Check the file location. Consider the time frame, and if the file should be under `ee`.
  - Check the tiers.
- Metrics instrumentations
  - Recommend using metrics instrumentation for new metrics, [if possible](metrics_instrumentation.md#support-for-instrumentation-classes).
- Approve the MR, and relabel the MR with `~"product intelligence::approved"`.

## Review workload distribution

[Danger bot](../dangerbot.md) adds the list of changed Product Intelligence files
and pings the
[`@gitlab-org/growth/product-intelligence/engineers`](https://gitlab.com/groups/gitlab-org/growth/product-intelligence/engineers/-/group_members?with_inherited_permissions=exclude) group for merge requests
that are not drafts.

Any of the Product Intelligence engineers can be assigned for the Product Intelligence review.
