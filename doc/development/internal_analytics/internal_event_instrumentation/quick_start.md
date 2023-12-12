---
stage: Monitor
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Quick start for Internal Event Tracking

In an effort to provide a more efficient, scalable, and unified tracking API, GitLab is deprecating existing RedisHLL and Snowplow tracking. Instead, we're implementing a new `track_event` (Backend) and `trackEvent`(Frontend) method.
With this approach, we can update both RedisHLL counters and send Snowplow events without worrying about the underlying implementation.

In order to instrument your code with Internal Events Tracking you need to do three things:

1. Define an event
1. Define one or more metrics
1. Trigger the event

## Defining event and metrics

<div class="video-fallback">
  See the video about <a href="https://www.youtube.com/watch?v=QICKWznLyy0">adding events and metrics using the generator</a>
</div>
<figure class="video_container">
  <iframe src="https://www.youtube-nocookie.com/embed/QICKWznLyy0" frameborder="0" allowfullscreen="true"> </iframe>
</figure>

To create an event and metric definitions you can use the `internal_events` generator.

This example creates an event definition for an event called `project_created` and two metric definitions, which are aggregated every 7 and 28 days.

```shell
bundle exec rails generate gitlab:analytics:internal_events \
--time_frames=7d 28d \
--group=project_management \
--event=project_created \
--unique=user.id \
--mr=https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121544
```

Where:

- `time_frames`: Valid options are `7d` and `28d` if you provide a `unique` value and `7d`, `28d` and `all` for metrics without `unique`.
- `unique`: Valid options are `user.id`, `project.id`, and `namespace.id`, as they are logged as part of the standard context. We [are actively working](https://gitlab.com/gitlab-org/gitlab/-/issues/411255) on a way to define uniqueness on arbitrary properties sent with the event, such as `merge_request.id`.

## Trigger events

Triggering an event and thereby updating a metric is slightly different on backend and frontend. Refer to the relevant section below.

### Backend tracking

To trigger an event, call the `Gitlab::InternalEvents.track_event` method with the desired arguments:

```ruby
Gitlab::InternalEvents.track_event(
        "i_code_review_user_apply_suggestion",
        user: user,
        namespace: namespace,
        project: project
        )
```

This method automatically increments all RedisHLL metrics relating to the event `i_code_review_user_apply_suggestion`, and sends a corresponding Snowplow event with all named arguments and standard context (SaaS only).

If you have defined a metric with a `unique` property such as `unique: project.id` it is required that you provide the `project` argument.

It is encouraged to fill out as many of `user`, `namespace` and `project` as possible as it increases the data quality and make it easier to define metrics in the future.

If a `project` but no `namespace` is provided, the `project.namespace` is used as the `namespace` for the event.

### Frontend tracking

Any frontend tracking call automatically passes the values `user.id`, `namespace.id`, and `project.id` from the current context of the page.

If you need to pass any further properties, such as `extra`, `context`, `label`, `property`, and `value`, you can use the [deprecated snowplow implementation](https://docs.gitlab.com/16.4/ee/development/internal_analytics/snowplow/implementation.html). In this case, let us know about your specific use-case in our [feedback issue for Internal Events](https://gitlab.com/gitlab-org/analytics-section/analytics-instrumentation/internal/-/issues/690).

#### Vue components

In Vue components, tracking can be done with [Vue mixin](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/tracking/internal_events.js#L29).

To implement Vue component tracking:

1. Import the `InternalEvents` library and call the `mixin` method:

     ```javascript
     import { InternalEvents } from '~/tracking';
     const trackingMixin = InternalEvents.mixin();
    ```

1. Use the mixin in the component:

   ```javascript
   export default {
     mixins: [trackingMixin],

     data() {
       return {
         expanded: false,
       };
     },
   };
   ```

1. Call the `trackEvent` method. Tracking options can be passed as the second parameter:

   ```javascript
   this.trackEvent('i_code_review_user_apply_suggestion');
   ```

   Or use the `trackEvent` method in the template:

   ```html
   <template>
     <div>
       <button data-testid="toggle" @click="toggle">Toggle</button>

       <div v-if="expanded">
         <p>Hello world!</p>
         <button @click="trackEvent('i_code_review_user_apply_suggestion')">Track another event</button>
       </div>
     </div>
   </template>
   ```

#### Raw JavaScript

For tracking events directly from arbitrary frontend JavaScript code, a module for raw JavaScript is provided. This can be used outside of a component context where the Mixin cannot be utilized.

```javascript
import { InternalEvents } from '~/tracking';
InternalEvents.trackEvent('i_code_review_user_apply_suggestion');
```

#### Data-track attribute

This attribute ensures that if we want to track GitLab internal events for a button, we do not need to write JavaScript code on Click handler. Instead, we can just add a data-event-tracking attribute with event value and it should work. This can also be used with HAML views.

```html
  <gl-button
    data-event-tracking="i_analytics_dev_ops_adoption"
  >
   Click Me
  </gl-button>
```

#### Haml

```haml
= render Pajamas::ButtonComponent.new(button_options: { class: 'js-settings-toggle',  data: { event_tracking: 'action' }}) do
```

#### Internal events on render

Sometimes we want to send internal events when the component is rendered or loaded. In these cases, we can add the `data-event-tracking-load="true"` attribute:

```haml
= render Pajamas::ButtonComponent.new(button_options: { data: { event_tracking_load: 'true', event_tracking: 'i_devops' } }) do
        = _("New project")
```
