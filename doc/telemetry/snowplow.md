# Snowplow tracking guide

## Frontend tracking

GitLab provides `Tracking`, an interface that wraps the [Snowplow JavaScript Tracker](https://github.com/snowplow/snowplow/wiki/javascript-tracker) for tracking custom events. There are a few ways to utilize tracking, but each generally requires at minimum, a `category` and an `action`. Additional data can be provided that adheres to our [Feature instrumentation taxonomy](https://about.gitlab.com/handbook/product/feature-instrumentation/#taxonomy).

| field      | type   | default value              | description |
|:-----------|:-------|:---------------------------|:------------|
| `category` | string | document.body.dataset.page | Page or subsection of a page that events are being captured within. |
| `action`   | string | 'generic'                  | Action the user is taking. Clicks should be `click` and activations should be `activate`, so for example, focusing a form field would be `activate_form_input`, and clicking a button would be `click_button`. |
| `data`     | object | {}                         | Additional data such as `label`, `property`, `value`, and `context` as described [in our Feature Instrumentation taxonomy](https://about.gitlab.com/handbook/product/feature-instrumentation/#taxonomy). |

### Tracking in HAML (or Vue Templates)

When working within HAML (or Vue templates) we can add `data-track-*` attributes to elements of interest. All elements that have a `data-track-event` attribute will automatically have event tracking bound on clicks.

Below is an example of `data-track-*` attributes assigned to a button:

```haml
%button.btn{ data: { track_event: "click_button", track_label: "template_preview", track_property: "my-template" } }
```

```html
<button class="btn"
  data-track-event="click_button"
  data-track-label="template_preview"
  data-track-property="my-template"
/>
```

Event listeners are bound at the document level to handle click events on or within elements with these data attributes. This allows for them to be properly handled on rerendering and changes to the DOM, but it's important to know that because of the way these events are bound, click events shouldn't be stopped from propagating up the DOM tree. If for any reason click events are being stopped from propagating, you'll need to implement your own listeners and follow the instructions in [Tracking in raw JavaScript](#tracking-in-raw-javascript).

Below is a list of supported `data-track-*` attributes:

| attribute             | required | description |
|:----------------------|:---------|:------------|
| `data-track-event`    | true     | Action the user is taking. Clicks must be prepended with `click` and activations must be prepended with `activate`. For example, focusing a form field would be `activate_form_input` and clicking a button would be `click_button`. |
| `data-track-label`    | false    | The `label` as described [in our Feature Instrumentation taxonomy](https://about.gitlab.com/handbook/product/feature-instrumentation/#taxonomy). |
| `data-track-property` | false    | The `property` as described [in our Feature Instrumentation taxonomy](https://about.gitlab.com/handbook/product/feature-instrumentation/#taxonomy). |
| `data-track-value`    | false    | The `value` as described [in our Feature Instrumentation taxonomy](https://about.gitlab.com/handbook/product/feature-instrumentation/#taxonomy). If omitted, this will be the elements `value` property or an empty string. For checkboxes, the default value will be the element's checked attribute or `false` when unchecked. |
| `data-track-context`  | false    | The `context` as described [in our Feature Instrumentation taxonomy](https://about.gitlab.com/handbook/product/feature-instrumentation/#taxonomy). |

### Tracking within Vue components

There's a tracking Vue mixin that can be used in components if more complex tracking is required. To use it, first import the `Tracking` library and request a mixin.

```javascript
import Tracking from '~/tracking';
const trackingMixin = Tracking.mixin({ label: 'right_sidebar' });
```

You can provide default options that will be passed along whenever an event is tracked from within your component. For instance, if all events within a component should be tracked with a given `label`, you can provide one at this time. Available defaults are `category`, `label`, `property`, and `value`. If no category is specified, `document.body.dataset.page` is used as the default.

You can then use the mixin normally in your component with the `mixin`, Vue declaration. The mixin also provides the ability to specify tracking options in `data` or `computed`. These will override any defaults and allows the values to be dynamic from props, or based on state.

```javascript
export default {
  mixins: [trackingMixin],
  // ...[component implementation]...
  data() {
    return {
      expanded: false,
      tracking: {
        label: 'left_sidebar'
      }
    };
  },
}
```

The mixin provides a `track` method that can be called within the template, or from component methods. An example of the whole implementation might look like the following.

```javascript
export default {
  mixins: [Tracking.mixin({ label: 'right_sidebar' })],
  data() {
    return {
      expanded: false,
    };
  },
  methods: {
    toggle() {
      this.expanded = !this.expanded;
      this.track('click_toggle', { value: this.expanded })
    }
  }
};
```

And if needed within the template, you can use the `track` method directly as well.

```html
<template>
  <div>
    <a class="toggle" @click.prevent="toggle">Toggle</a>
    <div v-if="expanded">
      <p>Hello world!</p>
      <a @click.prevent="track('click_action')">Track an event</a>
    </div>
  </div>
</template>
```

### Tracking in raw JavaScript

Custom event tracking and instrumentation can be added by directly calling the `Tracking.event` static function. The following example demonstrates tracking a click on a button by calling `Tracking.event` manually.

```javascript
import Tracking from '~/tracking';

const button = document.getElementById('create_from_template_button');
button.addEventListener('click', () => {
  Tracking.event('dashboard:projects:index', 'click_button', {
    label: 'create_from_template',
    property: 'template_preview',
    value: 'rails',
  });
})
```

### Tests and test helpers

In Jest particularly in vue tests, you can use the following:

```javascript
import { mockTracking } from 'helpers/tracking_helper';

describe('MyTracking', () => {
  let spy;

  beforeEach(() => {
    spy = mockTracking('_category_', wrapper.element, jest.spyOn);
  });

  it('tracks an event when clicked on feedback', () => {
    wrapper.find('.discover-feedback-icon').trigger('click');

    expect(spy).toHaveBeenCalledWith('_category_', 'click_button', {
      label: 'security-discover-feedback-cta',
      property: '0',
    });
  });
});

```

In obsolete Karma tests it's used as below:

```javascript
import { mockTracking, triggerEvent } from 'spec/helpers/tracking_helper';

describe('my component', () => {
  let trackingSpy;

  beforeEach(() => {
    const vm = mountComponent(MyComponent);
    trackingSpy = mockTracking('_category_', vm.$el, spyOn);
  });

  it('tracks an event when toggled', () => {
    triggerEvent('a.toggle');

    expect(trackingSpy).toHaveBeenCalledWith('_category_', 'click_edit_button', {
      label: 'right_sidebar',
      property: 'confidentiality',
    });
  });
});
```

## Backend tracking

GitLab provides `Gitlab::Tracking`, an interface that wraps the [Snowplow Ruby Tracker](https://github.com/snowplow/snowplow/wiki/ruby-tracker) for tracking custom events.

### Tracking in Ruby

Custom event tracking and instrumentation can be added by directly calling the `GitLab::Tracking.event` class method, which accepts the following arguments:

| argument   | type   | default value              | description |
|:-----------|:-------|:---------------------------|:------------|
| `category` | string | 'application'              | Area or aspect of the application. This could be `HealthCheckController` or `Lfs::FileTransformer` for instance. |
| `action`   | string | 'generic'                  | The action being taken, which can be anything from a controller action like `create` to something like an Active Record callback. |
| `data`     | object | {}                         | Additional data such as `label`, `property`, `value`, and `context` as described [in our Feature Instrumentation taxonomy](https://about.gitlab.com/handbook/product/feature-instrumentation/#taxonomy). These will be set as empty strings if you don't provide them. |

Tracking can be viewed as either tracking user behavior, or can be utilized for instrumentation to monitor and visual performance over time in an area or aspect of code.

For example:

```ruby
class Projects::CreateService < BaseService
  def execute
    project = Project.create(params)

    Gitlab::Tracking.event('Projects::CreateService', 'create_project',
      label: project.errors.full_messages.to_sentence,
      value: project.valid?
    )
  end
end
```

### Performance

We use the [AsyncEmitter](https://github.com/snowplow/snowplow/wiki/Ruby-Tracker#52-the-asyncemitter-class) when tracking events, which allows for instrumentation calls to be run in a background thread. This is still an active area of development.
