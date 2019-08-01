# Event Tracking

We use a tracking interface that wraps up [Snowplow](https://github.com/snowplow/snowplow) for tracking custom events. Snowplow implements page tracking, but also exposes custom event tracking.

The tracking interface can be imported in JS files as follows:

```javascript
import Tracking from `~/tracking`;
```

## Tracking in HAML or Vue templates

To avoid having to do create a bunch of custom javascript event handlers, when working within HAML or Vue templates, we can add `data-track-*` attributes to elements of interest. This way, all elements that have a `data-track-event` attribute to automatically have event tracking bound.

Below is an example of `data-track-*` attributes assigned to a button in HAML:

```haml
%button.btn{ data: { track_event: "click_button", track_label: "template_preview", track_property: "my-template", track_value: "" } }
```

We can then setup tracking for large sections of a page, or an entire page by telling the Tracking interface to bind to it.

```javascript
import Tracking from '~/tracking';

// for the entire document
new Tracking().bind();

// for a container element
document.addEventListener('DOMContentLoaded', () => {
  new Tracking('my_category').bind(document.getElementById('my-container'));
});

```

When you instantiate a Tracking instance you can provide a category. If none is provided, `document.body.dataset.page` will be used. When you bind the Tracking instance you can provide an element. If no element is provided to bind to, the `document` is assumed.

Below is a list of supported `data-track-*` attributes:

| attribute             | required | description |
|:----------------------|:---------|:------------|
| `data-track-event`    | true     | Action the user is taking. Clicks should be `click` and activations should be `activate`, so for example, focusing a form field would be `activate_form_input`, and clicking a button would be `click_button`. |
| `data-track-label`    | false    | The `label` as described [in our Feature Instrumentation taxonomy](https://about.gitlab.com/handbook/product/feature-instrumentation/#taxonomy) |
| `data-track-property` | false    | The `property` as described [in our Feature Instrumentation taxonomy](https://about.gitlab.com/handbook/product/feature-instrumentation/#taxonomy)
| `data-track-value`    | false    | The `value` as described [in our Feature Instrumentation taxonomy](https://about.gitlab.com/handbook/product/feature-instrumentation/#taxonomy). If omitted, this will be the elements `value` property or an empty string. For checkboxes, the default value will be the element's checked attribute or `false` when unchecked. 


## Tracking in raw Javascript

Custom events can be tracked by directly calling the `Tracking.event` static function, which accepts the following arguments:

| argument   | type   | default value              | description |
|:-----------|:-------|:---------------------------|:------------|
| `category` | string | document.body.dataset.page | Page or subsection of a page that events are being captured within. |
| `event`    | string | 'generic'                  | Action the user is taking. Clicks should be `click` and activations should be `activate`, so for example, focusing a form field would be `activate_form_input`, and clicking a button would be `click_button`. |
| `data`     | object | {}                         | Additional data such as `label`, `property`, and `value` as described [in our Feature Instrumentation taxonomy](https://about.gitlab.com/handbook/product/feature-instrumentation/#taxonomy). These will be set as empty strings if you don't provide them. |

Tracking can be programmatically added to an event of interest in Javascript, and the following example demonstrates tracking a click on a button by calling `Tracking.event` manually.

```javascript
import Tracking from `~/tracking`;

document.getElementById('my_button').addEventListener('click', () => {
  Tracking.event('dashboard:projects:index', 'click_button', {
    label: 'create_from_template',
    property: 'template_preview',
    value: 'rails',
  });
})
```


## Toggling tracking on or off

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
