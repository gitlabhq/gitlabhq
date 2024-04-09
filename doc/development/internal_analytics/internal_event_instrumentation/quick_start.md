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

To create event and/or metric definitions, use the `internal_events` generator from the `gitlab` directory:

```shell
ruby scripts/internal_events/cli.rb
```

This CLI will help you create the correct defintion files based on your specific use-case, then provide code examples for instrumentation and testing.

## Trigger events

Triggering an event and thereby updating a metric is slightly different on backend and frontend. Refer to the relevant section below.

### Backend tracking

<div class="video-fallback">
  Watch the video about <a href="https://www.youtube.com/watch?v=Teid7o_2Mmg">Backend instrumentation using Internal Events</a>
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/Teid7o_2Mmg" frameborder="0" allowfullscreen> </iframe>
</figure>

To trigger an event, call the `track_internal_event` method from the `Gitlab::InternalEventsTracking` module with the desired arguments:

```ruby
include Gitlab::InternalEventsTracking

track_internal_event(
  "i_code_review_user_apply_suggestion",
  user: user,
  namespace: namespace,
  project: project
)
```

This method automatically increments all RedisHLL metrics relating to the event `i_code_review_user_apply_suggestion`, and sends a corresponding Snowplow event with all named arguments and standard context (SaaS only).
In addition, the name of the class triggering the event is saved in the `category` property of the Snowplow event.

If you have defined a metric with a `unique` property such as `unique: project.id` it is required that you provide the `project` argument.

It is encouraged to fill out as many of `user`, `namespace` and `project` as possible as it increases the data quality and make it easier to define metrics in the future.

If a `project` but no `namespace` is provided, the `project.namespace` is used as the `namespace` for the event.

In some cases you might want to specify the `category` manually or provide none at all. To do that, you can call the `InternalEvents.track_event` method directly instead of using the module.

In case when a feature is enabled through multiple namespaces and its required to track why the feature is enabled, it is
possible to pass an optional `feature_enabled_by_namespace_ids` parameter with an array of namespace ids.

```ruby
Gitlab::InternalEvents.track_event(
  ...
  feature_enabled_by_namespace_ids: [namespace_one.id, namespace_two.id]
)
```

#### Additional properties

Additional properties can be passed when tracking events. They can be used to save additional data related to given event. It is possible to send a maximum of three additional properties with keys `label` (string), `property` (string) and `value`(numeric).

Additional properties are passed by including the `additional_properties` hash in the `#track_event` call:

```ruby
Gitlab::InternalEvents.track_event(
  "i_code_review_user_apply_suggestion",
  user: user,
  additional_properties: {
    label: 'admin',
    value: 20
  }
)
```

#### Controller and API helpers

There is a helper module `ProductAnalyticsTracking` for controllers you can use to track internal events for particular controller actions by calling `#track_internal_event`:

```ruby
class Projects::PipelinesController < Projects::ApplicationController
  include ProductAnalyticsTracking

  track_internal_event :charts, name: 'p_analytics_ci_cd_pipelines', conditions: -> { should_track_ci_cd_pipelines? }

  def charts
    ...
  end

  private

  def should_track_ci_cd_pipelines?
    params[:chart].blank? || params[:chart] == 'pipelines'
  end
end
```

You need to add these two methods to the controller body, so that the helper can get the current project and namespace for the event:

```ruby
  private

  def tracking_namespace_source
    project.namespace
  end

  def tracking_project_source
    project
  end
```

Also, there is an API helper:

```ruby
track_event(
  event_name,
  user: current_user,
  namespace_id: namespace_id,
  project_id: project_id
)
```

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

#### Data-event attribute

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

#### Additional properties

Additional properties can be passed when tracking events. They can be used to save additional data related to given event. It is possible to send a maximum of three additional properties with keys `label` (string), `property` (string) and `value`(numeric).

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

For data-event attributes:

```javascript
 <gl-button
    data-event-tracking="i_analytics_dev_ops_adoption"
    data-event-label="gitlab_devops_button_label"
    data-event-property="nav_core_menu"
  >
   Click Me
  </gl-button>
```

For Haml:

```haml
= render Pajamas::ButtonComponent.new(button_options: { class: 'js-settings-toggle',  data: { event_tracking: 'action', event_label: 'gitlab_settings_button_label', event_property: 'settings_menu', event_value: 2 }}) do
```
