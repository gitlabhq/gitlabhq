---
stage: Analytics
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Service Ping review guidelines

This page includes introductory material for a
[Product Intelligence](https://about.gitlab.com/handbook/engineering/development/analytics/product-intelligence/)
review, and is specific to Service Ping related reviews. For broader advice and
general best practices for code reviews, refer to our [code review guide](../code_review.md).

## Resources for reviewers

- [Service Ping Guide](index.md)
- [Metrics Dictionary](https://metrics.gitlab.com/)

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
  [engineer](https://gitlab.com/groups/gitlab-org/analytics-section/product-intelligence/engineers/-/group_members?with_inherited_permissions=exclude) from the Product Intelligence team for a review.
- Set the correct attributes in the metric's YAML definition:
  - `product_section`, `product_stage`, `product_group`
  - Provide a clear description of the metric.
- Add a changelog [according to guidelines](../changelog.md).

#### The Product Intelligence **reviewer** should

- Perform a first-pass review on the merge request and suggest improvements to the author.
- Check the [metrics location](metrics_dictionary.md#metric-key_path) in
  the Service Ping JSON payload.
- Suggest that the author checks the [naming suggestion](metrics_dictionary.md#generate-a-metric-name-suggestion) while
  generating the metric's YAML definition.
- Add the `~database` label and ask for a [database review](../database_review.md) for
  metrics that are based on Database.
- Add `~Data Warehouse::Impact Check` for any database metric that has a query change. Changes in queries can affect [data operations](https://about.gitlab.com/handbook/business-technology/data-team/how-we-work/triage/#gitlabcom-db-structure-changes).
- For tracking using Redis HLL (HyperLogLog):
  - Check if a [feature flag is needed](implement.md#recommendations).
- For a metric's YAML definition:
  - Check the metric's `description`.
  - Check the metric's `key_path`.
  - Check the `product_section`, `product_stage`, and `product_group` fields.
    Read the [stages file](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml).
  - Check the file location. Consider the time frame, and if the file should be under `ee`.
  - Check the tiers.
- If a metric was changed or removed: Make sure the MR author notified the Customer Success Ops team (`@csops-team`), Analytics Engineers (`@gitlab-data/analytics-engineers`), and Product Analysts (`@gitlab-data/product-analysts`) by `@` mentioning those groups in a comment on the issue for the MR and all of these groups have acknowledged the removal.
- Metrics instrumentations
  - Recommend using metrics instrumentation for new metrics, [if possible](metrics_instrumentation.md#support-for-instrumentation-classes).
- Approve the MR, and relabel the MR with `~"product intelligence::approved"`.

## Review workload distribution

[Danger bot](../dangerbot.md) adds the list of changed Product Intelligence files
and pings the
[`@gitlab-org/analytics-section/product-intelligence/engineers`](https://gitlab.com/groups/gitlab-org/analytics-section/product-intelligence/engineers/-/group_members?with_inherited_permissions=exclude) group for merge requests
that are not drafts.

Any of the Product Intelligence engineers can be assigned for the Product Intelligence review.
