---
stage: Monitor
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Migrating existing tracking to internal event tracking

GitLab Internal Events Tracking exposes a unified API on top of the deprecated Snowplow and Redis/RedisHLL event tracking options.

This page describes how you can switch from one of the previous methods to using Internal Events Tracking.

NOTE:
Tracking events directly via Snowplow, Redis/RedisHLL is deprecated but won't be removed in the foreseeable future.
While we encourage you to migrate to Internal Event tracking the deprecated methods will continue to work for existing events and metrics.

## Migrating from existing Snowplow tracking

If you are already tracking events in Snowplow, you can also start collecting metrics from self-managed instances by switching to Internal Events Tracking.

The event triggered by Internal Events has some special properties compared to previously tracking with Snowplow directly:

1. The `label`, `property` and `value` attributes are not used within Internal Events and are always empty.
1. The `category` is automatically set to `InternalEventTracking`

Make sure that you are okay with this change before you migrate and dashboards are changed accordingly.

### Backend

If you are already tracking Snowplow events using `Gitlab::Tracking.event` and you want to migrate to Internal Events Tracking you might start with something like this:

```ruby
Gitlab::Tracking.event(name, 'ci_templates_unique', namespace: namespace,
                               project: project, context: [context], user: user, label: label)
```

The code above can be replaced by this:

```ruby
Gitlab::InternalEvents.track_event('ci_templates_unique', namespace: namespace, project: project, user: user)
```

In addition, you have to create definitions for the metrics that you would like to track.

To generate metric definitions, you can use the generator like this:

```shell
bin/rails g gitlab:analytics:internal_events \
  --time_frames=7d 28d\
  --group=project_management \
  --event=ci_templates_unique \
  --unique=user.id \
  --mr=https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121544
```

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
this.trackEvent('action')
```

You can use [this MR](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/123901/diffs) as an example. It migrates the `devops_adoption_app` component to use Internal Events Tracking.

If you are using `data-track-action` in the component, you have to change it to `data-event-tracking` to migrate to Internal Events Tracking.

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

1. Create an event definition that describes `git_write_action` ([guide](event_definition_guide.md)).
1. Find metric definitions that list `git_write_action` in the events section (`20210216182041_action_monthly_active_users_git_write.yml` and `20210216184045_git_write_action_weekly.yml`).
1. Change the `data_source` from `redis_hll` to `internal_events` in the metric definition files.
1. Add an `events` section to both metric definition files.

    ```yaml
    events:
      - name: git_write_action
        unique: user.id
    ```

   Use `project.id` or `namespace.id` instead of `user.id` if your metric is counting something other than unique users.
1. Call `InternalEvents.tract_event` instead of `HLLRedisCounter.track_event`:

    ```diff
    - Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:git_write_action, values: current_user.id)
    + Gitlab::InternalEvents.track_event('project_created', user: current_user)
    ```

1. Optional. Add additional values to the event. You typically want to add `project` and `namespace` as it is useful information to have in the data warehouse.

    ```diff
    - Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:git_write_action, values: current_user.id)
    + Gitlab::InternalEvents.track_event('project_created', user: current_user, project: project, namespace: namespace)
    ```

1. Update your test to use the `internal event tracking` shared example.

### Frontend

If you are calling `trackRedisHllUserEvent` in the frontend to track the frontend event, you can convert this to Internal events by using mixin, raw JavaScript or data tracking attribute,

[Quick start guide](quick_start.md#frontend-tracking) has example for each methods.
