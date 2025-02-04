---
stage: Monitor
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Metric lifecycle
---

The following guidelines explain the steps to follow at each stage of a metric's lifecycle.

## Add a new metric

Follow the [metrics instrumentation](metrics_instrumentation.md) guide.

## Change an existing metric

WARNING:
We want to **PREVENT** changes to the calculation logic or important attributes on any metric as this invalidates comparisons of the same metric across different versions of GitLab.

If you change a metric, you have to consider that not all instances of GitLab are running on the newest version. Old instances will still report the old version of the metric.
Additionally, a metric's reported numbers are primarily interesting compared to previously reported numbers.
As a result, if you need to change one of the following parts of a metric, you need to add a new metric instead. It's your choice whether to keep the old metric alongside the new one or [remove it](#remove-a-metric).

- **calculation logic**: This means any changes that can produce a different value than the previous implementation
- **YAML attributes**: The following attributes are directly used for analysis or calculation: `key_path`, `time_frame`, `value_type`, `data_source`.

If you change the `performance_indicator_type` attribute of a metric or think your case needs an exception from the outlined rules then notify the Customer Success Ops team (`@csops-team`), Analytics Engineers (`@gitlab-data/analytics-engineers`), and Product Analysts (`@gitlab-data/product-analysts`) teams by `@` mentioning those groups in a comment on the merge request or issue.

You can change any other attributes without impact to the calculation or analysis. See [this video tutorial](https://youtu.be/bYf3c01KCls) for help updating metric attributes.

Currently, the [Metrics Dictionary](https://metrics.gitlab.com/) is built automatically once a day. You can see the change in the dictionary within 24 hours when you change the metric's YAML file.

## Remove a metric

1. Create an issue for removing the metric if none exists yet. The issue needs to outline why the metric should be removed. You can use this issue to document the removal process.

   - **If the metric has at least one `performance_indicator_type` of the `[x]mau` or `customer_health_score` kind**:
     Notify the Customer Success Ops team (`@csops-team`), Analytics Engineers (`@gitlab-data/analytics-engineers`), and Product Analysts (`@gitlab-data/product-analysts`) by `@` mentioning the groups in a comment in the issue. Unexpected changes to these metric could break reporting.
   - **If the metric is owned by a different group than the one doing the removal**:
     Tag the PM and EM of the owning group according to the [stages file](https://gitlab.com/gitlab-com/www-gitlab-com/blob/master/data/stages.yml).

1. Remove the metric instrumentation code, depending on `data_source`:

   - **`database/system`**: If the metric has an `instrumentation_class` and the assigned class is no longer used by any other metric you can remove the class and specs.
     If the metric is instrumented within [`lib/gitlab/usage_data.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/usage_data.rb)
     or [`ee/lib/ee/gitlab/usage_data.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ee/gitlab/usage_data.rb) then remove the associated code and specs
     ([example](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/60149/diffs#6335dc533bd21df26db9de90a02dd66278c2390d_167_167)).
   - **`redis_hll/redis/internal_events`**: Remove the tracking code e.g. `track_internal_event` and associated specs.

1. Update the attributes of the metric's YAML definition:

   - Set the `status:` to `removed`.
   - Set `removed_by_url:` to the URL of the MR removing the metric
   - Set `milestone_removed:` to the number of the
     milestone in which the metric was removed.

   Do not remove the metric's YAML definition altogether. Some self-managed instances might not immediately update to the latest version of GitLab, and
   therefore continue to report the removed metric. The Analytics Instrumentation team requires a record of all removed metrics to identify and filter them.

## Group name changes

When the name of a group that owns events or metrics is changed, the `product_group` property should be updated in all metric and event definitions belonging to that group.

The `product_group_renamer` script can update all the definitions so you do not have to do it manually.

For example, if the group 5-min-app was renamed to 2-min-app, you can update the relevant files like this:

```shell
$ scripts/internal_events/product_group_renamer.rb 5-min-app 2-min-app
Updated '5-min-app' to '2-min-app' in 3 files

Updated files:
  config/metrics/schema/product_groups.json
  config/metrics/counts_28d/20210216184517_p_ci_templates_5_min_production_app_monthly.yml
  config/metrics/counts_7d/20210216184515_p_ci_templates_5_min_production_app_weekly.yml
```

After running the script, you must commit all the modified files to Git and create a merge request.

The script is part of GDK and a frontend or backend developer can run the script and prepare the merge request.

If a group is split into multiple groups, you need to manually update the product_group.
