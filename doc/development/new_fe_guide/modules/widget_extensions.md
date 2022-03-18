---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Merge request widget extensions **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/44616) in GitLab 13.6.

## Summary

Extensions in the merge request widget enable you to add new features
into the merge request widget that match the design framework.
With extensions we get a lot of benefits out of the box without much effort required, like:

- A consistent look and feel.
- Tracking when the extension is opened.
- Virtual scrolling for performance.

## Usage

To use extensions you must first create a new extension object to fetch the
data to render in the extension. For a working example, refer to the example file in
`app/assets/javascripts/vue_merge_request_widget/extensions/issues.js`.

The basic object structure:

```javascript
export default {
  name: '',       // Required: This helps identify the widget
  props: [],      // Required: Props passed from the widget state
  i18n: {         // Required: Object to hold i18n text
    label: '',    // Required: Used for tooltips and aria-labels
    loading: '',  // Required: Loading text for when data is loading
  },
  expandEvent: '',      // Optional: RedisHLL event name to track expanding content
  enablePolling: false, // Optional: Tells extension to poll for data
  computed: {
    summary(data) {},     // Required: Level 1 summary text
    statusIcon(data) {},  // Required: Level 1 status icon
    tertiaryButtons() {}, // Optional: Level 1 action buttons
  },
  methods: {
    fetchCollapsedData(props) {}, // Required: Fetches data required for collapsed state
    fetchFullData(props) {},      // Required: Fetches data for the full expanded content
  },
};
```

By following the same data structure, each extension can follow the same registering structure,
but each extension can manage its data sources.

After creating this structure, you must register it. You can register the extension at any
point _after_ the widget has been created. To register a extension:

```javascript
// Import the register method
import { registerExtension } from '~/vue_merge_request_widget/components/extensions';

// Import the new extension
import issueExtension from '~/vue_merge_request_widget/extensions/issues';

// Register the imported extension
registerExtension(issueExtension);
```

## Data fetching

Each extension must fetch data. Fetching is handled when registering the extension,
not by the core component itself. This approach allows for various different
data fetching methods to be used, such as GraphQL or REST API calls.

### API calls

For performance reasons, it is best if the collapsed state fetches only the data required to
render the collapsed state. This fetching happens within the `fetchCollapsedData` method.
This method is called with the props as an argument, so you can easily access
any paths set in the state.

To allow the extension to set the data, this method **must** return the data. No
special formatting is required. When the extension receives this data,
it is set to `collapsedData`. You can access `collapsedData` in any computed property or
method.

When the user clicks **Expand**, the `fetchFullData` method is called. This method
also gets called with the props as an argument. This method **must** also return
the full data. However, this data needs to be correctly formatted to match the format
mentioned in the data structure section.

#### Technical debt

For some of the current extensions, there is no split in data fetching. All the data
is fetched through the `fetchCollapsedData` method. While less performant,
it allows for faster iteration.

To handle this the `fetchFullData` returns the data set through
the `fetchCollapsedData` method call. In these cases, the `fetchFullData` must
return a promise:

```javascript
fetchCollapsedData() {
  return ['Some data'];
},
fetchFullData() {
  return Promise.resolve(this.collapsedData)
},
```

### Data structure

The data returned from `fetchFullData` must match the format below. This format
allows the core component to render the data in a way that matches
the design framework. Any text properties can use the styling placeholders
mentioned below:

```javascript
{
  id: data.id,    // Required: ID used as a key for each row
  header: 'Header' || ['Header', 'sub-header'], // Required: String or array can be used for the header text
  text: '',       // Required: Main text for the row
  subtext: '',    // Optional: Smaller sub-text to be displayed below the main text
  icon: {         // Optional: Icon object
    name: EXTENSION_ICONS.success, // Required: The icon name for the row
  },
  badge: {        // Optional: Badge displayed after text
    text: '',     // Required: Text to be displayed inside badge
    variant: '',  // Optional: GitLab UI badge variant, defaults to info
  },
  actions: [],    // Optional: Action button for row
  children: [],   // Optional: Child content to render, structure matches the same structure
}
```

### Polling

To enable polling for an extension, an options flag must be present in the extension:

```javascript
export default {
  //...
  enablePolling: true
};
```

This flag tells the base component we should poll the `fetchCollapsedData()`
defined in the extension. Polling stops if the response has data, or if an error is present.

When writing the logic for `fetchCollapsedData()`, a complete Axios response must be returned
from the method. The polling utility needs data like polling headers to work correctly:

```javascript
export default {
  //...
  enablePolling: true
  methods: {
    fetchCollapsedData() {
      return axios.get(this.reportPath)
    },
  },
};
```

Most of the time the data returned from the extension's endpoint is not in the format
the UI needs. We must format the data before setting the collapsed data in the base component.

If the computed property `summary` can rely on `collapsedData`, you can format the data
when `fetchFullData` is invoked:

```javascript
export default {
  //...
  enablePolling: true
  methods: {
    fetchCollapsedData() {
      return axios.get(this.reportPath)
    },
     fetchFullData() {
      return Promise.resolve(this.prepareReports());
    },
    // custom method
    prepareReports() {
      // unpack values from collapsedData
      const { new_errors, existing_errors, resolved_errors } = this.collapsedData;

      // perform data formatting

      return [...newErrors, ...existingErrors, ...resolvedErrors]
    }
  },
};
```

If the extension relies on `collapsedData` being formatted before invoking `fetchFullData()`,
then `fetchCollapsedData()` must return the Axios response as well as the formatted data:

```javascript
export default {
  //...
  enablePolling: true
  methods: {
    fetchCollapsedData() {
      return axios.get(this.reportPath).then(res => {
        const formattedData = this.prepareReports(res.data)

        return {
          ...res,
          data: formattedData,
        }
      })
    },
    // Custom method
    prepareReports() {
      // Unpack values from collapsedData
      const { new_errors, existing_errors, resolved_errors } = this.collapsedData;

      // Perform data formatting

      return [...newErrors, ...existingErrors, ...resolvedErrors]
    }
  },
};
```

### Errors

If `fetchCollapsedData()` or `fetchFullData()` methods throw an error:

- The loading state of the extension is updated to `LOADING_STATES.collapsedError`
  and `LOADING_STATES.expandedError` respectively.
- The extensions header displays an error icon and updates the text to be either:
  - The text defined in `$options.i18n.error`.
  - "Failed to load" if `$options.i18n.error` is not defined.
- The error is sent to Sentry to log that it occurred.

To customise the error text, add it to the `i18n` object in your extension:

```javascript
export default {
  //...
  i18n: {
    //...
    error: __('Your error text'),
  },
};
```

## Icons

Level 1 and all subsequent levels can have their own status icons. To keep with
the design framework, import the `EXTENSION_ICONS` constant
from the `constants.js` file:

```javascript
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants.js';
```

This constant has the below icons available for use. Per the design framework,
only some of these icons should be used on level 1:

- `failed`
- `warning`
- `success`
- `neutral`
- `error`
- `notice`
- `severityCritical`
- `severityHigh`
- `severityMedium`
- `severityLow`
- `severityInfo`
- `severityUnknown`

## Text styling

Any area that has text can be styled with the placeholders below. This
technique follows the same technique as `sprintf`. However, instead of specifying
these through `sprintf`, the extension does this automatically.

Every placeholder contains starting and ending tags. For example, `success` uses
`Hello %{success_start}world%{success_end}`. The extension then
adds the start and end tags with the correct styling classes.

| Placeholder | Style |
|---|---|
| success | `gl-font-weight-bold gl-text-green-500` |
| danger | `gl-font-weight-bold gl-text-red-500` |
| critical | `gl-font-weight-bold gl-text-red-800` |
| same | `gl-font-weight-bold gl-text-gray-700` |
| strong | `gl-font-weight-bold` |
| small | `gl-font-sm` |

## Action buttons

You can add action buttons to all level 1 and 2 in each extension. These buttons
are meant as a way to provide links or actions for each row:

- Action buttons for level 1 can be set through the `tertiaryButtons` computed property.
  This property should return an array of objects for each action button.
- Action buttons for level 2 can be set by adding the `actions` key to the level 2 rows object.
  The value for this key must also be an array of objects for each action button.

Links must follow this structure:

```javascript
{
  text: 'Click me',
  href: this.someLinkHref,
  target: '_blank', // Optional
}
```

For internal action buttons, follow this structure:

```javascript
{
  text: 'Click me',
  onClick() {}
}
```
