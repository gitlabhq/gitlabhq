---
stage: Analytics
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Service Ping metric lifecycle

The following guidelines explain the steps to follow at each stage of a metric's lifecycle.

## Add a new metric

Follow the [Implement Service Ping](implement.md) guide.

## Change an existing metric

See [this video tutorial](https://youtu.be/bYf3c01KCls) for help with the update of metric attributes.

NOTE:
The `key_path` attribute represents the location of the metric in Service Ping payload and must not be changed.

Because we do not control when customers update their self-managed instances of GitLab,
we **STRONGLY DISCOURAGE** changes to the logic used to calculate any metric.
Any such changes lead to inconsistent reports from multiple GitLab instances.
If there is a problem with an existing metric, it's best to deprecate the existing metric,
and use it, side by side, with the desired new metric.

If you do need to change a metric, please notify the Customer Success Ops team (`@csops-team`), Analytics Engineers (`@gitlab-data/analytics-engineers`), and Product Analysts (`@gitlab-data/product-analysts`) teams by `@` mentioning those groups in a comment on the MR.
Many Service Ping metrics are relied upon for health score and XMAU reporting and
unexpected changes to those metrics could break reporting.

Example:
Consider following change. Before GitLab 12.6, the `example_metric` was implemented as:

```ruby
{
  ...
  example_metric: distinct_count(Project, :creator_id)
}
```

For GitLab 12.6, the metric was changed to filter out archived projects:

```ruby
{
  ...
  example_metric: distinct_count(Project.non_archived, :creator_id)
}
```

In this scenario, all instances running up to GitLab 12.5 continue to report `example_metric`,
including all archived projects, while all instances running GitLab 12.6 and higher filters
out such projects. As Service Ping data is collected from all reporting instances, the
resulting dataset includes mixed data, which distorts any following business analysis.

The correct approach is to add a new metric for GitLab 12.6 release with updated logic:

```ruby
{
  ...
  example_metric_without_archived: distinct_count(Project.non_archived, :creator_id)
}
```

and update existing business analysis artefacts to use `example_metric_without_archived` instead of `example_metric`

Currently, the [Metrics Dictionary](https://metrics.gitlab.com/) is built automatically once a day. When a change to a metric is made in a YAML file, you can see the change in the dictionary within 24 hours.

## Remove a metric

WARNING:
If a metric is not used in Sisense or any other system after 6 months, the
Product Intelligence team marks it as inactive and assigns it to the group owner for review.

We are working on automating this process. See [this epic](https://gitlab.com/groups/gitlab-org/-/epics/8988) for details.

Product Intelligence removes metrics from Service Ping if they are not used in any Sisense dashboard.

For an example of the metric removal process, see this [example issue](https://gitlab.com/gitlab-org/gitlab/-/issues/388236).

To remove a metric:

1. Create an issue for removing the metric if none exists yet. The issue needs to outline why the metric should be deleted. You can use this issue to document the removal process.

1. Verify the metric is not used to calculate the conversational index. The
   conversational index is a measure that reports back to self-managed instances
   to inform administrators of the progress of DevOps adoption for the instance.

   You can check
   [`CalculateConvIndexService`](https://gitlab.com/gitlab-services/version-gitlab-com/-/blob/master/app/services/calculate_conv_index_service.rb)
   to view the metrics that are used. The metrics are represented
   as the keys that are passed as a field argument into the `get_value` method.

1. Verify that removing the metric from the Service Ping payload does not cause
   errors in [Version App](https://gitlab.com/gitlab-services/version-gitlab-com)
   when the updated payload is collected and processed. Version App collects
   and persists all Service Ping reports. To verify Service Ping processing in your local development environment, follow this [guide](https://www.youtube.com/watch?v=FS5emplabRU).
   Alternatively, you can modify [fixtures](https://gitlab.com/gitlab-services/version-gitlab-com/-/blob/master/spec/support/usage_data_helpers.rb#L540)
   used to test the [`UsageDataController#create`](https://gitlab.com/gitlab-services/version-gitlab-com/-/blob/3760ef28/spec/controllers/usage_data_controller_spec.rb#L75)
   endpoint, and assure that test suite does not fail when metric that you wish to remove is not included into test payload.

1. Remove data from Redis

   For [Ordinary Redis](implement.md#ordinary-redis-counters) counters remove data stored in Redis.

   - Add a migration to remove the data from Redis for the related Redis keys. For more details, see [this MR example](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/82604/diffs).

1. Create an issue in the
   [GitLab Data Team project](https://gitlab.com/gitlab-data/analytics/-/issues).
   Ask for confirmation that the metric is not referred to in any SiSense dashboards and
   can be safely removed from Service Ping. Use this
   [example issue](https://gitlab.com/gitlab-data/analytics/-/issues/15266) for guidance.

1. Notify the Customer Success Ops team (`@csops-team`), Analytics Engineers (`@gitlab-data/analytics-engineers`), and Product Analysts (`@gitlab-data/product-analysts`) by `@` mentioning those groups in a comment in the issue from step 1 regarding the deletion of the metric.
   Many Service Ping metrics are relied upon for health score and XMAU reporting and unexpected changes to those metrics could break reporting.

1. After you verify the metric can be safely removed,
   update the attributes of the metric's YAML definition:

   - Set the `status:` to `removed`.
   - Set `removed_by_url:` to the URL of the MR removing the metric
   - Set `milestone_removed:` to the number of the
     milestone in which the metric was removed.

   Do not remove the metric's YAML definition altogether. Some self-managed
   instances might not immediately update to the latest version of GitLab, and
   therefore continue to report the removed metric. The Product Intelligence team
   requires a record of all removed metrics to identify and filter them.

   For example please take a look at this [merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60149/diffs#b01f429a54843feb22265100c0e4fec1b7da1240_10_10).

1. After you verify the metric can be safely removed,
   remove the metric's instrumentation from
   [`lib/gitlab/usage_data.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/usage_data.rb)
   or
   [`ee/lib/ee/gitlab/usage_data.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ee/gitlab/usage_data.rb).

   For example please take a look at this [merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60149/diffs#6335dc533bd21df26db9de90a02dd66278c2390d_167_167).

1. Remove any other records related to the metric:
   - The feature flag YAML file at [`config/feature_flags/*/*.yaml`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/config/feature_flags).
   - The entry in the known events YAML file at [`lib/gitlab/usage_data_counters/known_events/*.yaml`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/usage_data_counters/known_events).
