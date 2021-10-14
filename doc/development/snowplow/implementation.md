---
stage: Growth
group: Product Intelligence
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Implement Snowplow tracking

This guide describes how to implement and test Snowplow tracking using JavaScript and Ruby trackers.

## Snowplow JavaScript frontend tracking

GitLab provides a `Tracking` interface that wraps the [Snowplow JavaScript tracker](https://docs.snowplowanalytics.com/docs/collecting-data/collecting-from-own-applications/javascript-trackers/) to track custom events. For the recommended implementation type, see [Usage recommendations](#usage-recommendations).

Tracking implementations must have an `action` and a `category`. You can provide additional [structured event taxonomy](index.md#structured-event-taxonomy) categories with an `extra` object that accepts key-value pairs.

| Field      | Type   | Default value              | Description                                                                                                                                                                                                    |
|:-----------|:-------|:---------------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `category` | string | `document.body.dataset.page` | Page or subsection of a page in which events are captured.                                                                                                                                            |
| `action`   | string | generic                  | Action the user is taking. Clicks must be `click` and activations must be `activate`. For example, focusing a form field is `activate_form_input`, and clicking a button is `click_button`. |
| `data`     | object | `{}`                         | Additional data such as `label`, `property`, `value`, `context` as described in [Structured event taxonomy](index.md#structured-event-taxonomy), and `extra` (key-value pairs object). |

### Usage recommendations

- Use [data attributes](#implement-data-attribute-tracking) on HTML elements that emit `click`, `show.bs.dropdown`, or `hide.bs.dropdown` events.
- Use the [Vue mixin](#implement-vue-component-tracking) for tracking custom events, or if the supported events for data attributes are not propagating.
- Use the [tracking class](#implement-raw-javascript-tracking) when tracking raw JavaScript files.

### Implement data attribute tracking

To implement tracking for HAML or Vue templates, add a [`data-track` attribute](#data-track-attributes) to the element.

The following example shows `data-track-*` attributes assigned to a button:

```haml
%button.btn{ data: { track: { action: "click_button", label: "template_preview", property: "my-template" } } }
```

```html
<button class="btn"
  data-track-action="click_button"
  data-track-label="template_preview"
  data-track-property="my-template"
  data-track-extra='{ "template_variant": "primary" }'
/>
```

#### `data-track` attributes

| Attribute             | Required | Description |
|:----------------------|:---------|:------------|
| `data-track-action`    | true     | Action the user is taking. Clicks must be prepended with `click` and activations must be prepended with `activate`. For example, focusing a form field is `activate_form_input` and clicking a button is `click_button`. Replaces `data-track-event`, which was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/290962) in GitLab 13.11. |
| `data-track-label`    | false    | The `label` as described in [structured event taxonomy](index.md#structured-event-taxonomy). |
| `data-track-property` | false    | The `property` as described in [structured event taxonomy](index.md#structured-event-taxonomy). |
| `data-track-value`    | false    | The `value` as described in [structured event taxonomy](index.md#structured-event-taxonomy). If omitted, this is the element's `value` property or `undefined`. For checkboxes, the default value is the element's checked attribute or `0` when unchecked. |
| `data-track-extra` | false    | A key-value pairs object passed as a valid JSON string. This is added to the `extra` property in our [`gitlab_standard`](schemas.md#gitlab_standard) schema. |
| `data-track-context`  | false    | The `context` as described in our [Structured event taxonomy](index.md#structured-event-taxonomy). |

#### Event listeners

Event listeners are bound at the document level to handle click events in elements with data attributes. This allows them to be handled on re-rendering and changes to the DOM. Because of the way these events are bound, click events should not stop from propagating up the DOM tree. If click events are stopped from propagating, you must implement listeners and follow the instructions in [Implement Vue component tracking](#implement-vue-component-tracking) or [Implement raw JavaScript tracking](#implement-raw-javascript-tracking).

#### Available helpers

```ruby
tracking_attrs(label, action, property) # { data: { track_label... } }

%button{ **tracking_attrs('main_navigation', 'click_button', 'navigation') }
```

#### Caveats

When using the GitLab helper method [`nav_link`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/helpers/tab_helper.rb#L76) be sure to wrap `html_options` under the `html_options` keyword argument.
Be careful, as this behavior can be confused with the `ActionView` helper method [`link_to`](https://api.rubyonrails.org/v5.2.3/classes/ActionView/Helpers/UrlHelper.html#method-i-link_to) that does not require additional wrapping of `html_options`

```ruby
# Bad
= nav_link(controller: ['dashboard/groups', 'explore/groups'], data: { track_label: "explore_groups", track_action: "click_button" })

# Good
= nav_link(controller: ['dashboard/groups', 'explore/groups'], html_options: { data: { track_label: "explore_groups", track_action: "click_button" } })

# Good (other helpers)
= link_to explore_groups_path, title: _("Explore"), data: { track_label: "explore_groups", track_action: "click_button" }
```

### Implement Vue component tracking

For custom event tracking, use a Vue `mixin` in components. Vue `mixin` exposes the `Tracking.event` static method and the `track` method called from components or templates. You can specify tracking options in `data` or `computed`. These options override any defaults and allow the values to be dynamic from props or based on state.

Default options are passed when an event is tracked from the component. If you don't specify an option, the default `document.body.dataset.page` is used. The default options are:

- `category`
- `label`
- `property`
- `value`

To implement Vue component tracking:

1. Import the `Tracking` library and request a `mixin`:

    ```javascript
    import Tracking from '~/tracking';
    const trackingMixin = Tracking.mixin;
    ```

1. Provide categories to track the event from the component. For example, to track all events in a component with a label, use the `label` category:

    ```javascript
    import Tracking from '~/tracking';
    const trackingMixin = Tracking.mixin({ label: 'right_sidebar' });
    ```

1. In the component, declare the Vue `mixin`.

    ```javascript
    export default {
      mixins: [trackingMixin],
      // ...[component implementation]...
      data() {
        return {
          expanded: false,
          tracking: {
            label: 'left_sidebar',
          },
        };
      },
    };
    ```

1. To receive event data as a tracking object or computed property:
   - Declare it in the `data` function. Use a `tracking` object when default event properties are dynamic or provided at runtime:

      ```javascript
      export default {
        name: 'RightSidebar',
        mixins: [Tracking.mixin()],
        data() {
          return {
            tracking: {
              label: 'right_sidebar',
              // category: '',
              // property: '',
              // value: '',
              // experiment: '',
              // extra: {},
            },
          };
        },
      };
      ```

   - Declare it in the event data in the `track` function. This object merges with any previously provided options:

      ```javascript
      this.track('click_button', {
        label: 'right_sidebar',
      });
      ```

1. Optional. Use the `track` method in a template:

    ```html
    <template>
      <div>
        <button data-testid="toggle" @click="toggle">Toggle</button>

        <div v-if="expanded">
          <p>Hello world!</p>
          <button @click="track('click_action')">Track another event</button>
        </div>
      </div>
    </template>
    ```

#### Implementation example

```javascript
export default {
  name: 'RightSidebar',
  mixins: [Tracking.mixin({ label: 'right_sidebar' })],
  data() {
    return {
      expanded: false,
    };
  },
  methods: {
    toggle() {
      this.expanded = !this.expanded;
      // Additional data will be merged, like `value` below
      this.track('click_toggle', { value: Number(this.expanded) });
    }
  }
};
```

#### Testing example

```javascript
import { mockTracking } from 'helpers/tracking_helper';
// mockTracking(category, documentOverride, spyMethod)

describe('RightSidebar.vue', () => {
  let trackingSpy;
  let wrapper;

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
  });

  const findToggle = () => wrapper.find('[data-testid="toggle"]');

  it('tracks turning off toggle', () => {
    findToggle().trigger('click');

    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_toggle', {
      label: 'right_sidebar',
      value: 0,
    });
  });
});
```

### Implement raw JavaScript tracking

To call custom event tracking and instrumentation directly from the JavaScript file, call the `Tracking.event` static function.

The following example demonstrates tracking a click on a button by manually calling `Tracking.event`.

```javascript
import Tracking from '~/tracking';

const button = document.getElementById('create_from_template_button');

button.addEventListener('click', () => {
  Tracking.event('dashboard:projects:index', 'click_button', {
    label: 'create_from_template',
    property: 'template_preview',
    extra: {
      templateVariant: 'primary',
      valid: 1,
    },
  });
});
```

#### Testing example

```javascript
import Tracking from '~/tracking';

describe('MyTracking', () => {
  let wrapper;

  beforeEach(() => {
    jest.spyOn(Tracking, 'event');
  });

  const findButton = () => wrapper.find('[data-testid="create_from_template"]');

  it('tracks event', () => {
    findButton().trigger('click');

    expect(Tracking.event).toHaveBeenCalledWith(undefined, 'click_button', {
      label: 'create_from_template',
      property: 'template_preview',
      extra: {
        templateVariant: 'primary',
        valid: true,
      },
    });
  });
});
```

### Form tracking

Enable Snowplow automatic [form tracking](https://docs.snowplowanalytics.com/docs/collecting-data/collecting-from-own-applications/javascript-trackers/javascript-tracker/javascript-tracker-v2/tracking-specific-events/#form-tracking) by calling `Tracking.enableFormTracking` (after the DOM is ready) and providing a `config` object that includes at least one of the following elements:

- `forms`: determines which forms are tracked, and are identified by the CSS class name.
- `fields`: determines which fields inside the tracked forms are tracked, and are identified by the field `name`.

An optional list of contexts can be provided as the second argument.
Note that our [`gitlab_standard`](schemas.md#gitlab_standard) schema is excluded from these events.

```javascript
Tracking.enableFormTracking({
  forms: { allow: ['sign-in-form', 'password-recovery-form'] },
  fields: { allow: ['terms_and_conditions', 'newsletter_agreement'] },
});
```

#### Testing example

```javascript
import Tracking from '~/tracking';

describe('MyFormTracking', () => {
  let formTrackingSpy;

  beforeEach(() => {
    formTrackingSpy = jest
      .spyOn(Tracking, 'enableFormTracking')
      .mockImplementation(() => null);
  });

  it('initialized with the correct configuration', () => {
    expect(formTrackingSpy).toHaveBeenCalledWith({
      forms: { allow: ['sign-in-form', 'password-recovery-form'] },
      fields: { allow: ['terms_and_conditions', 'newsletter_agreement'] },
    });
  });
});
```

## Implement Snowplow Ruby (Backend) tracking

GitLab provides `Gitlab::Tracking`, an interface that wraps the [Snowplow Ruby Tracker](https://docs.snowplowanalytics.com/docs/collecting-data/collecting-from-own-applications/ruby-tracker/) for tracking custom events.

Custom event tracking and instrumentation can be added by directly calling the `GitLab::Tracking.event` class method, which accepts the following arguments:

| argument   | type                      | default value | description                                                                                                                       |
|------------|---------------------------|---------------|-----------------------------------------------------------------------------------------------------------------------------------|
| `category` | String                    |               | Area or aspect of the application. This could be `HealthCheckController` or `Lfs::FileTransformer` for instance.                  |
| `action`   | String                    |               | The action being taken, which can be anything from a controller action like `create` to something like an Active Record callback. |
| `label`    | String                    | nil           | As described in [Structured event taxonomy](index.md#structured-event-taxonomy).                                                          |
| `property` | String                    | nil           | As described in [Structured event taxonomy](index.md#structured-event-taxonomy).                                                          |
| `value`    | Numeric                   | nil           | As described in [Structured event taxonomy](index.md#structured-event-taxonomy).                                                          |
| `context`  | Array\[SelfDescribingJSON\] | nil           | An array of custom contexts to send with this event. Most events should not have any custom contexts.                             |
| `project`  | Project                   | nil           | The project associated with the event. |
| `user`     | User                      | nil           | The user associated with the event. |
| `namespace` | Namespace                | nil           | The namespace associated with the event. |
| `extra`   | Hash                | `{}`         | Additional keyword arguments are collected into a hash and sent with the event. |

Tracking can be viewed as either tracking user behavior, or can be used for instrumentation to monitor and visualize performance over time in an area or aspect of code.

For example:

```ruby
class Projects::CreateService < BaseService
  def execute
    project = Project.create(params)

    Gitlab::Tracking.event('Projects::CreateService', 'create_project', label: project.errors.full_messages.to_sentence,
                           property: project.valid?.to_s, project: project, user: current_user, namespace: namespace)
  end
end
```

### Unit testing

Use the `expect_snowplow_event` helper when testing backend Snowplow events. See [testing best practices](
https://docs.gitlab.com/ee/development/testing_guide/best_practices.html#test-snowplow-events) for details.

### Performance

We use the [AsyncEmitter](https://docs.snowplowanalytics.com/docs/collecting-data/collecting-from-own-applications/ruby-tracker/emitters/#the-asyncemitter-class) when tracking events, which allows for instrumentation calls to be run in a background thread. This is still an active area of development.

## Develop and test Snowplow

There are several tools for developing and testing a Snowplow event.

| Testing Tool                                 | Frontend Tracking  | Backend Tracking    | Local Development Environment | Production Environment | Production Environment |
|----------------------------------------------|--------------------|---------------------|-------------------------------|------------------------|------------------------|
| Snowplow Analytics Debugger Chrome Extension | **{check-circle}** | **{dotted-circle}** | **{check-circle}**            | **{check-circle}**     | **{check-circle}**     |
| Snowplow Inspector Chrome Extension          | **{check-circle}** | **{dotted-circle}** | **{check-circle}**            | **{check-circle}**     | **{check-circle}**     |
| Snowplow Micro                               | **{check-circle}** | **{check-circle}**  | **{check-circle}**            | **{dotted-circle}**    | **{dotted-circle}**    |
| Snowplow Mini                                | **{check-circle}** | **{check-circle}**  | **{dotted-circle}**           | **{status_preparing}** | **{status_preparing}** |

**Legend**

**{check-circle}** Available, **{status_preparing}** In progress, **{dotted-circle}** Not Planned

### Test frontend events

To test frontend events in development:

- [Enable Snowplow tracking in the Admin Area](index.md#enable-snowplow-tracking).
- Turn off any ad blockers that would prevent Snowplow JS from loading in your environment.
- Turn off "Do Not Track" (DNT) in your browser.

All URLs are pseudonymized. The entity identifier [replaces](https://docs.snowplowanalytics.com/docs/collecting-data/collecting-from-own-applications/javascript-trackers/javascript-tracker/javascript-tracker-v2/tracker-setup/other-parameters-2/#Setting_a_custom_page_URL_and_referrer_URL) personally identifiable
information (PII). PII includes usernames, group, and project names.

#### Snowplow Analytics Debugger Chrome Extension

Snowplow Analytics Debugger is a browser extension for testing frontend events. This works on production, staging, and local development environments.

1. Install the [Snowplow Analytics Debugger](https://chrome.google.com/webstore/detail/snowplow-analytics-debugg/jbnlcgeengmijcghameodeaenefieedm) Chrome browser extension.
1. Open Chrome DevTools to the Snowplow Analytics Debugger tab.
1. Learn more at [Igloo Analytics](https://www.iglooanalytics.com/blog/snowplow-analytics-debugger-chrome-extension.html).

#### Snowplow Inspector Chrome Extension

Snowplow Inspector Chrome Extension is a browser extension for testing frontend events. This works on production, staging and local development environments.

1. Install [Snowplow Inspector](https://chrome.google.com/webstore/detail/snowplow-inspector/maplkdomeamdlngconidoefjpogkmljm?hl=en).
1. Open the Chrome extension by pressing the Snowplow Inspector icon beside the address bar.
1. Click around on a webpage with Snowplow and you should see JavaScript events firing in the inspector window.

### Snowplow Micro

Snowplow Micro is a very small version of a full Snowplow data collection pipeline: small enough that it can be launched by a test suite. Events can be recorded into Snowplow Micro just as they can a full Snowplow pipeline. Micro then exposes an API that can be queried.

Snowplow Micro is a Docker-based solution for testing frontend and backend events in a local development environment. You must modify GDK using the instructions below to set this up.

- Read [Introducing Snowplow Micro](https://snowplowanalytics.com/blog/2019/07/17/introducing-snowplow-micro/)
- Look at the [Snowplow Micro repository](https://github.com/snowplow-incubator/snowplow-micro)
- Watch our <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [installation guide recording](https://www.youtube.com/watch?v=OX46fo_A0Ag)

1. Ensure Docker is installed and running.

1. Install [Snowplow Micro](https://github.com/snowplow-incubator/snowplow-micro) by cloning the settings in [this project](https://gitlab.com/gitlab-org/snowplow-micro-configuration):
1. Navigate to the directory with the cloned project, and start the appropriate Docker
   container with the following script:

   ```shell
   ./snowplow-micro.sh
   ```

1. Use GDK to start the PostgreSQL terminal and connect to the `gitlabhq_development` database:

   ```shell
   gdk psql -d gitlabhq_development
   ```

1. Update your instance's settings to enable Snowplow events and point to the Snowplow Micro collector:

   ```shell
   update application_settings set snowplow_collector_hostname='localhost:9090', snowplow_enabled=true, snowplow_cookie_domain='.gitlab.com';
   ```

1. Update `DEFAULT_SNOWPLOW_OPTIONS` in `app/assets/javascripts/tracking/constants.js` to remove `forceSecureTracker: true`:

   ```diff
   diff --git a/app/assets/javascripts/tracking/constants.js b/app/assets/javascripts/tracking/constants.js
   index 598111e4086..eff38074d4c 100644
   --- a/app/assets/javascripts/tracking/constants.js
   +++ b/app/assets/javascripts/tracking/constants.js
   @@ -7,7 +7,6 @@ export const DEFAULT_SNOWPLOW_OPTIONS = {
      appId: '',
      userFingerprint: false,
      respectDoNotTrack: true,
   -  forceSecureTracker: true,
      eventMethod: 'post',
      contexts: { webPage: true, performanceTiming: true },
      formTracking: false,
   ```

1. Update `options` in `lib/gitlab/tracking.rb` to add `protocol` and `port`:

   ```diff
   diff --git a/lib/gitlab/tracking.rb b/lib/gitlab/tracking.rb
   index 618e359211b..e9084623c43 100644
   --- a/lib/gitlab/tracking.rb
   +++ b/lib/gitlab/tracking.rb
   @@ -41,7 +41,9 @@ def options(group)
              cookie_domain: Gitlab::CurrentSettings.snowplow_cookie_domain,
              app_id: Gitlab::CurrentSettings.snowplow_app_id,
              form_tracking: additional_features,
   -          link_click_tracking: additional_features
   +          link_click_tracking: additional_features,
   +          protocol: 'http',
   +          port: 9090
            }.transform_keys! { |key| key.to_s.camelize(:lower).to_sym }
          end
   ```

1. Update `emitter` in `lib/gitlab/tracking/destinations/snowplow.rb` to change `protocol`:

   ```diff
   diff --git a/lib/gitlab/tracking/destinations/snowplow.rb b/lib/gitlab/tracking/destinations/snowplow.rb
   index 4fa844de325..5dd9d0eacfb 100644
   --- a/lib/gitlab/tracking/destinations/snowplow.rb
   +++ b/lib/gitlab/tracking/destinations/snowplow.rb
   @@ -40,7 +40,7 @@ def tracker
            def emitter
              SnowplowTracker::AsyncEmitter.new(
                Gitlab::CurrentSettings.snowplow_collector_hostname,
   -            protocol: 'https'
   +            protocol: 'http'
              )
            end
          end

   ```

1. Restart GDK:

   ```shell
   gdk restart
   ```

1. Send a test Snowplow event from the Rails console:

   ```ruby
   Gitlab::Tracking.event('category', 'action')
   ```

1. Navigate to `localhost:9090/micro/good` to see the event.

### Snowplow Mini

[Snowplow Mini](https://github.com/snowplow/snowplow-mini) is an easily-deployable, single-instance version of Snowplow.

Snowplow Mini can be used for testing frontend and backend events on a production, staging and local development environment.

For GitLab.com, we're setting up a [QA and Testing environment](https://gitlab.com/gitlab-org/telemetry/-/issues/266) using Snowplow Mini.

### Troubleshooting

To control content security policy warnings when using an external host, you can allow or disallow them by modifying `config/gitlab.yml`. To allow them, add the relevant host for `connect_src`. For example, for `https://snowplow.trx.gitlab.net`:

```yaml
development:
  <<: *base
  gitlab:
    content_security_policy:
      enabled: true
      directives:
        connect_src: "'self' http://localhost:* http://127.0.0.1:* ws://localhost:* wss://localhost:* ws://127.0.0.1:* https://snowplow.trx.gitlab.net/"
```
