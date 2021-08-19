---
stage: Growth
group: Product Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Service Ping metric lifecycle

The following guidelines explain the steps to follow at each stage of a metric's lifecycle.

## Add a new metric

Please follow the [Implementing Service Ping](index.md#implementing-service-ping) guide.

## Change an existing metric

Because we do not control when customers update their self-managed instances of GitLab,
we **STRONGLY DISCOURAGE** changes to the logic used to calculate any metric.
Any such changes lead to inconsistent reports from multiple GitLab instances.
If there is a problem with an existing metric, it's best to deprecate the existing metric,
and use it, side by side, with the desired new metric.

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

In this scenario all instances running up to GitLab 12.5 continue to report `example_metric`,
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

## Deprecate a metric

If a metric is obsolete and you no longer use it, you can mark it as deprecated.

For an example of the metric deprecation process take a look at this [example merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/59899)

To deprecate a metric:

1. Check the following YAML files and verify the metric is not used in an aggregate:
   - [`config/metrics/aggregates/*.yaml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/metrics/aggregates/)
   - [`ee/config/metrics/aggregates/*.yaml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/config/metrics/aggregates/)

1. Create an issue in the [GitLab Data Team
   project](https://gitlab.com/gitlab-data/analytics/-/issues). Ask for
   confirmation that the metric is not used by other teams, or in any of the SiSense
   dashboards.

1. Verify the metric is not used to calculate the conversational index. The
   conversational index is a measure that reports back to self-managed instances
   to inform administrators of the progress of DevOps adoption for the instance.

   You can check
   [`CalculateConvIndexService`](https://gitlab.com/gitlab-services/version-gitlab-com/-/blob/master/app/services/calculate_conv_index_service.rb)
   to view the metrics that are used. The metrics are represented
   as the keys that are passed as a field argument into the `get_value` method.

1. Document the deprecation in the metric's YAML definition. Set
   the `status:` attribute to `deprecated`, for example:

   ```yaml
   ---
   key_path: analytics_unique_visits.analytics_unique_visits_for_any_target_monthly
   description: Visits to any of the pages listed above per month
   product_section: dev
   product_stage: manage
   product_group: group::analytics
   product_category:
   value_type: number
   status: deprecated
   time_frame: 28d
   data_source:
   distribution:
   - ce
   tier:
   - free
   ```

1. Replace the metric's instrumentation with a fixed value. This avoids wasting
   resources to calculate the deprecated metric. In
   [`lib/gitlab/usage_data.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/usage_data.rb)
   or
   [`ee/lib/ee/gitlab/usage_data.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ee/gitlab/usage_data.rb),
   replace the code that calculates the metric's value with a fixed value that
   indicates it's deprecated:

   ```ruby
   module Gitlab
     class UsageData
       DEPRECATED_VALUE = -1000

       def analytics_unique_visits_data
         results['analytics_unique_visits_for_any_target'] = redis_usage_data { unique_visit_service.unique_visits_for(targets: :analytics) }
         results['analytics_unique_visits_for_any_target_monthly'] = DEPRECATED_VALUE

         { analytics_unique_visits: results }
       end
     # ...
     end
   end
   ```

## Remove a metric

### Removal policy

WARNING:
A metric that is not used in Sisense or any other system after 6 months is marked by the
Product Intelligence team as inactive and is assigned to the group owner for review.

We are working on automating this process. See [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/338466) for details.

Only deprecated metrics can be removed from Service Ping.

For an example of the metric removal process take a look at this [example issue](https://gitlab.com/gitlab-org/gitlab/-/issues/297029)

### To remove a deprecated metric

1. Verify that removing the metric from the Service Ping payload does not cause
   errors in [Version App](https://gitlab.com/gitlab-services/version-gitlab-com)
   when the updated payload is collected and processed. Version App collects
   and persists all Service Ping reports. To do that you can modify
   [fixtures](https://gitlab.com/gitlab-services/version-gitlab-com/-/blob/master/spec/support/usage_data_helpers.rb#L540)
   used to test
   [`UsageDataController#create`](https://gitlab.com/gitlab-services/version-gitlab-com/-/blob/3760ef28/spec/controllers/usage_data_controller_spec.rb#L75)
   endpoint, and assure that test suite does not fail when metric that you wish to remove is not included into test payload.

1. Create an issue in the
   [GitLab Data Team project](https://gitlab.com/gitlab-data/analytics/-/issues).
   Ask for confirmation that the metric is not referred to in any SiSense dashboards and
   can be safely removed from Service Ping. Use this
   [example issue](https://gitlab.com/gitlab-data/analytics/-/issues/7539) for guidance.
   This step can be skipped if verification done during [deprecation process](#deprecate-a-metric)
   reported that metric is not required by any data transformation in Snowflake data warehouse nor it is
   used by any of SiSense dashboards.

1. After you verify the metric can be safely removed,
   update the attributes of the metric's YAML definition:

   - Set the `status:` to `removed`.
   - Set `milestone_removed:` to the number of the
     milestone in which the metric was removed.

   Do not remove the metric's YAML definition altogether. Some self-managed
   instances might not immediately update to the latest version of GitLab, and
   therefore continue to report the removed metric. The Product Intelligence team
   requires a record of all removed metrics in order to identify and filter them.

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
