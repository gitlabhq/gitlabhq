---
stage: Monitor
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Migrating existing tracking to internal event tracking
---

GitLab Internal Events Tracking exposes a unified API on top of the deprecated Snowplow and Redis/RedisHLL event tracking options.

This page describes how you can switch from one of the previous methods to using Internal Events Tracking.

NOTE:
Tracking events directly via Snowplow, Redis/RedisHLL is deprecated but won't be removed in the foreseeable future.
While we encourage you to migrate to Internal Event tracking the deprecated methods will continue to work for existing events and metrics.

## Migrating from existing Snowplow tracking

If you are already tracking events in Snowplow, you can also start collecting metrics from self-managed instances by switching to Internal Events Tracking.

The event triggered by Internal Events has some special properties compared to previously tracking with Snowplow directly:

1. The `category` is automatically set to the location where the event happened. For Frontend events it is the page name and for Backend events it is a class name. If the page name or class name is not used, the default value of `"InternalEventTracking"` will be used.

Make sure that you are okay with this change before you migrate and dashboards are changed accordingly.

### Backend

If you are already tracking Snowplow events using `Gitlab::Tracking.event` and you want to migrate to Internal Events Tracking you might start with something like this:

```ruby
Gitlab::Tracking.event(name, 'ci_templates_unique', namespace: namespace,
                               project: project, context: [context], user: user, label: label)
```

The code above can be replaced by this:

```ruby
include Gitlab::InternalEventsTracking

track_internal_event('ci_templates_unique', namespace: namespace, project: project, user: user, additional_properties: { label: label })
```

The `label`, `property` and `value` attributes need to be sent inside the `additional_properties` hash. In case they were not included in the original call, the `additional_properties` argument can be skipped.

In addition, you have to create definitions for the metrics that you would like to track.

To generate metric definitions, you can use the generator:

```shell
scripts/internal_events/cli.rb
```

The generator walks you through the required inputs step-by-step.

### Frontend

If you are using the `Tracking` mixin in the Vue component, you can replace it with the `InternalEvents` mixin.

For example, if your current Vue component look like this:

```vue
import Tracking from '~/tracking';
...
mixins: [Tracking.mixin()]
...
...
this.track('some_label', options)
```

After converting it to Internal Events Tracking, it should look like this:

```vue
import { InternalEvents } from '~/tracking';
...
mixins: [InternalEvents.mixin()]
...
...
this.trackEvent('action', {}, 'category')
```

If you are currently passing `category` and need to keep it, it can be passed as the third argument in the `trackEvent` method, as illustrated in the previous example. Nonetheless, it is strongly advised against using the `category` parameter for new events. This is because, by default, the category field is populated with information about where the event was triggered.

You can use [this MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123901/diffs) as an example. It migrates the `devops_adoption_app` component to use Internal Events Tracking.

If you are using `label`, `value`, and `property` in Snowplow tracking, you can pass them as an object as the third argument to the `trackEvent` function. It is an optional parameter.

For Vue Mixin:

```javascript
   this.trackEvent('i_code_review_user_apply_suggestion', {
    label: 'push_event',
    property: 'golang',
    value: 20
   });
```

For raw JavaScript:

```javascript
   InternalEvents.trackEvent('i_code_review_user_apply_suggestion', {
    label: 'admin',
    property: 'system',
    value: 20
   });
```

If you are using `data-track-action` in the component, you have to change it to `data-event-tracking` to migrate to Internal Events Tracking. If there are additional tracking attributes like `data-track-label`, `data-track-property` and `data-track-value` then you can replace them with `data-event-label`, `data-event-property` and `data-event-value` respectively. If you want to pass any additional property as a custom key-value pair, you can use `data-event-additional` attribute.

For example, if a button is defined like this:

```vue
 <gl-button
  :href="diffFile.external_url"
  :title="externalUrlLabel"
  :aria-label="externalUrlLabel"
  target="_blank"
  data-track-action="click_toggle_external_button"
  data-track-label="diff_toggle_external_button"
  data-track-property="diff_toggle_external"
  icon="external-link"
/>
```

This can be converted to Internal Events Tracking like this:

```vue
 <gl-button
  :href="diffFile.external_url"
  :title="externalUrlLabel"
  :aria-label="externalUrlLabel"
  target="_blank"
  data-event-tracking="click_toggle_external_button"
  data-event-label="diff_toggle_external_button"
  data-event-property="diff_toggle_external"
  data-event-additional='{"key1": "value1", "key2": "value2"}'
  icon="external-link"
/>
```

Notice that we just need action to pass in the `data-event-tracking` attribute which will be passed to both Snowplow and RedisHLL.

## Migrating from tracking with RedisHLL

### Backend

If you are currently tracking a metric in `RedisHLL` like this:

```ruby
  Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:git_write_action, values: current_user.id)
```

To start using Internal Events Tracking, follow these steps:

1. If event is not being sent to Snowplow, consider renaming if to meet [our naming convention](quick_start.md#defining-event-and-metrics).
1. Create an event definition that describes `git_write_action` ([guide](event_definition_guide.md)).
1. Find metric definitions that list `git_write_action` in the events section (`20210216182041_action_monthly_active_users_git_write.yml` and `20210216184045_git_write_action_weekly.yml`).
1. Change the `data_source` from `redis_hll` to `internal_events` in the metric definition files.
1. Remove the `instrumentation_class` property. It's not used for Internal Events metrics.
1. Add an `events` section to both metric definition files.

   ```yaml
   events:
     - name: git_write_action
       unique: user.id
   ```

   Use `project.id` or `namespace.id` instead of `user.id` if your metric is counting something other than unique users.
1. Remove the `options` section from both metric definition files.
1. Include the `Gitlab::InternalEventsTracking` module and call `track_internal_event` instead of `HLLRedisCounter.track_event`:

   ```diff
   - Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:git_write_action, values: current_user.id)
   + include Gitlab::InternalEventsTracking
   + track_internal_event('project_created', user: current_user)
   ```

1. Optional. Add additional values to the event. You typically want to add `project` and `namespace` as it is useful information to have in the data warehouse.

   ```diff
   - Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:git_write_action, values: current_user.id)
   + include Gitlab::InternalEventsTracking
   + track_internal_event('project_created', user: current_user, project: project, namespace: namespace)
   ```

1. Update your test to use the `internal event tracking` shared example.

1. Remove the event's name from [hll_redis_legacy_events](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/usage_data_counters/hll_redis_legacy_events.yml)

1. Add the event to [hll_redis_key_overrides](https://gitlab.com/gitlab-org/gitlab/blob/master/lib/gitlab/usage_data_counters/hll_redis_key_overrides.yml) file. The format used in this file is: `project_created-user: 'project_created'`, where `project_created` is the event's name and `user` is the unique value that has been specified in the metric definition files.

### Frontend

You can convert `trackRedisHllUserEvent` calls to Internal events by using the mixin, raw JavaScript, or the `data-event-tracking` attribute.

[Quick start guide](quick_start.md#frontend-tracking) has examples for each method.
