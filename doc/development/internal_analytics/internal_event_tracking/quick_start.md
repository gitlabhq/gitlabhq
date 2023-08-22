---
stage: Analytics
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Quick start for Internal Event Tracking

In an effort to provide a more efficient, scalable, and unified tracking API, GitLab is deprecating existing RedisHLL and Snowplow tracking. Instead, we're implementing a new `track_event` method.
With this approach, we can update both RedisHLL counters and send Snowplow events without worrying about the underlying implementation.

In order to instrument your code with Internal Events Tracking need three things:

1. Define an event
1. Define one or more metrics
1. Trigger the event

## Defining event and metrics

To create event and metric definitions you can use the `internal_events` generator.

This example will create an event definition for an event called `project_created` and two metric definitions which will be aggregated every 7 and 28 days.

```shell
bin/rails g gitlab:analytics:internal_events \
--time_frames=7d 28d \
--group=project_management \
--stage=plan --section=dev \
--event=project_created \
--unique=user.id \
--mr=https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121544
```

## Trigger events

Triggering an event and thereby updating a metric is slightly different on backend and frontend. Please refer to the relevant section below.

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

### Frontend tracking

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

1. Call the `track_event` method. Tracking options can be passed as the second parameter:

   ```javascript
   this.track_event('i_code_review_user_apply_suggestion');
   ```

   Or use the `track_event` method in the template:

   ```html
   <template>
     <div>
       <button data-testid="toggle" @click="toggle">Toggle</button>

       <div v-if="expanded">
         <p>Hello world!</p>
         <button @click="track_event('i_code_review_user_apply_suggestion')">Track another event</button>
       </div>
     </div>
   </template>
   ```

#### Raw JavaScript

For tracking events directly from arbitrary frontend JavaScript code, a module for raw JavaScript is provided. This can be used outside of a component context where the Mixin cannot be utilized.

```javascript
import { InternalEvents } from '~/tracking';
InternalEvents.track_event('i_code_review_user_apply_suggestion');
```

#### Data-track attribute

This attribute ensures that if we want to track GitLab internal events for a button, we do not need to write JavaScript code on Click handler. Instead, we can just add a data-event-tracking attribute with event value and it should work. This can also be used with haml views.

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

### Limitations

The only values we allow for `unique` are `user.id`, `project.id`, and `namespace.id`, as they are logged as part of the standard context. We currently don't have anywhere to put a value like `merge_request.id`. That will change with self-describing events.
