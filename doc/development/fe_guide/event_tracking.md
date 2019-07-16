# Event Tracking

We use [Snowplow](https://github.com/snowplow/snowplow) for tracking custom events (available in GitLab [Enterprise Edition](https://about.gitlab.com/pricing/) only).

## Generic tracking function

In addition to Snowplow's built-in method for tracking page views, we use a generic tracking function which enables us to selectively apply listeners to events.

The generic tracking function can be imported in EE-specific JS files as follows:

```javascript
import { trackEvent } from `ee/stats`;
```

This gives the user access to the `trackEvent` method, which takes the following parameters:

| parameter        | type   | description                                                                                                                                                                                                                                                                                                                            | required |
| ---------------- | ------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| `category`       | string | Describes the page that you're capturing click events on. Unless infeasible, please use the Rails page attribute `document.body.dataset.page` by default.                                                                                                                                                                              | true     |
| `eventName`      | string | Describes the action the user is taking. The first word should always describe the action. For example, clicks should be `click` and activations should be `activate`. Use underscores to describe what was acted on. For example, activating a form field would be `activate_form_input`. Clicking on a dropdown is `click_dropdown`. | true     |
| `additionalData` | object | Additional data such as `label`, `property`, and `value` as described [in our Feature Instrumentation taxonomy](https://about.gitlab.com/handbook/product/feature-instrumentation/#taxonomy).                                                                                                                                          | false    |

Read more about instrumentation and the taxonomy in the [Product Handbook](https://about.gitlab.com/handbook/product/feature-instrumentation).

### Tracking in `.js` and `.vue` files

The most simple use case is to add tracking programmatically to an event of interest in Javascript.

The following example demonstrates how to track a click on a button in Javascript by calling the `trackEvent` method explicitly:

```javascript
import { trackEvent } from `ee/stats`;

trackEvent('dashboard:projects:index', 'click_button', {
    label: 'create_from_template',
    property: 'template_preview',
    value: 'rails',
});
```

### Tracking in HAML templates

Sometimes we want to track clicks for multiple elements on a page. Creating event handlers for all elements could soon turn into a tedious task.

There's a more convenient solution to this problem. When working with HAML templates, we can add `data-track-*` attributes to elements of interest. This way, all elements that have both `data-track-label` and `data-track-event` attributes assigned get marked for event tracking. All we have to do is call the `bindTrackableContainer` method on a container which allows for better scoping.

Below is an example of `data-track-*` attributes assigned to a button in HAML:

```ruby
%button.btn{ data: { track_label: "template_preview", track_property: "my-template", track_event: "click_button", track_value: "" } }
```

By calling `bindTrackableContainer('.my-container')`, click handlers get bound to all elements located in `.my-container` provided that they have the necessary `data-track-*` attributes assigned to them.

```javascript
import Stats from 'ee/stats';

document.addEventListener('DOMContentLoaded', () => {
  Stats.bindTrackableContainer('.my-container', 'category');
});
```

The second parameter in `bindTrackableContainer` is optional. If omitted, the value of `document.body.dataset.page` will be used as category instead.

Below is a list of supported `data-track-*` attributes:

| attribute             | description                                                                                                                                                                                                     | required |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| `data-track-label`    | The `label` in `trackEvent`                                                                                                                                                                                     | true     |
| `data-track-event`    | The `eventName` in `trackEvent`                                                                                                                                                                                 | true     |
| `data-track-property` | The `property` in `trackEvent`. If omitted, an empty string will be used as a default value.                                                                                                                    | false    |
| `data-track-value`    | The `value` in `trackEvent`. If omitted, this will be `target.value` or empty string. For checkboxes, the default value being tracked will be the element's checked attribute if `data-track-value` is omitted. | false    |

Since Snowplow is an Enterprise Edition feature, it's necessary to create a CE backport when adding `data-track-*` attributes to HAML templates in most cases.

## Testing

Snowplow can be enabled by navigating to:

- **Admin area > Settings > Integrations** in the UI.
- `admin/application_settings/integrations` in your browser.

The following configuration is required:

| Name          | Value                     |
| ------------- | ------------------------- |
| Collector     | `snowplow.trx.gitlab.net` |
| Site ID       | `gitlab`                  |
| Cookie domain | `.gitlab.com`             |

Now the implemented tracking events can be inspected locally by looking at the network panel of the browser's development tools.
