---
stage: Create
group: Code Review
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Merge request widget extensions

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/44616) in GitLab 13.6.

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
  modalComponent: null, // Optional: The component to use for the modal
  telemetry: true,      // Optional: Reports basic telemetry for the extension. Set to false to disable telemetry
  computed: {
    summary(data) {},     // Required: Level 1 summary text
    statusIcon(data) {},  // Required: Level 1 status icon
    tertiaryButtons() {}, // Optional: Level 1 action buttons
    shouldCollapse(data) {}, // Optional: Add logic to determine if the widget can expand or not
  },
  methods: {
    fetchCollapsedData(props) {}, // Required: Fetches data required for collapsed state
    fetchFullData(props) {},      // Required: Fetches data for the full expanded content
    fetchMultiData() {},          // Optional: Works in conjunction with `enablePolling` and allows polling multiple endpoints
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
render the collapsed state. This fetching happens in the `fetchCollapsedData` method.
This method is called with the props as an argument, so you can easily access
any paths set in the state.

To allow the extension to set the data, this method **must** return the data. No
special formatting is required. When the extension receives this data,
it is set to `collapsedData`. You can access `collapsedData` in any computed property or
method.

When the user selects **Expand**, the `fetchFullData` method is called. This method
also gets called with the props as an argument. This method **must** also return
the full data. However, this data must be correctly formatted to match the format
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
  link: {         // Optional: Link to a URL displayed after text
    text: '',     // Required: Text of the link
    href: '',     // Optional: URL for the link
  },
  modal: {        // Optional: Link to open a modal displayed after text
    text: '',     // Required: Text of the link
    onClick: () => {} // Optional: Function to run when link is clicked, i.e. to set this.modalData
  }
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

If the extension must poll multiple endpoints at the same time, then `fetchMultiData`
can be used to return an array of functions. A new `poll` object is created for each
endpoint and they are polled separately. After all endpoints are resolved, polling is
stopped and `setCollapsedData` is called with an array of `response.data`.

```javascript
export default {
  //...
  enablePolling: true
  methods: {
    fetchMultiData() {
      return [
        () => axios.get(this.reportPath1),
        () => axios.get(this.reportPath2),
        () => axios.get(this.reportPath3)
    },
  },
};
```

WARNING:
The function must return a `Promise` that resolves the `response` object.
The implementation relies on the `POLL-INTERVAL` header to keep polling, therefore it is
important not to alter the status code and headers.

### Errors

If `fetchCollapsedData()` or `fetchFullData()` methods throw an error:

- The loading state of the extension is updated to `LOADING_STATES.collapsedError` if
  `fetchCollapsedData()` method throws an error.
- The loading state of the extension is updated to `LOADING_STATES.expandedError` if
  `fetchFullData()` method throws an error.
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

## Telemetry

The base implementation of the widget extension framework includes some telemetry events.
Each widget reports:

- `view`: When it is rendered to the screen.
- `expand`: When it is expanded.
- `full_report_clicked`: When an (optional) input is clicked to view the full report.
- Outcome (`expand_success`, `expand_warning`, or `expand_failed`): One of three
  additional events relating to the status of the widget when it was expanded.

### Add new widgets

When adding new widgets, the above events must be marked as `known`, and have metrics
created, to be reportable.

NOTE:
Events that are only for EE should include `--ee` at the end of both shell commands below.

To generate these known events for a single widget:

1. Widgets should be named `Widget${CamelName}`.
   - For example: a widget for **Test Reports** should be `WidgetTestReports`.
1. Compute the widget name slug by converting the `${CamelName}` to lower-, snake-case.
   - The previous example would be `test_reports`.
1. Add the new widget name slug to `lib/gitlab/usage_data_counters/merge_request_widget_extension_counter.rb`
   in the `WIDGETS` list.
1. Ensure the GDK is running (`gdk start`).
1. Generate known events on the command line with the following command.
   Replace `test_reports` with your appropriate name slug:

   ```shell
   bundle exec rails generate gitlab:usage_metric_definition \
   counts.i_code_review_merge_request_widget_test_reports_count_view \
   counts.i_code_review_merge_request_widget_test_reports_count_full_report_clicked \
   counts.i_code_review_merge_request_widget_test_reports_count_expand \
   counts.i_code_review_merge_request_widget_test_reports_count_expand_success \
   counts.i_code_review_merge_request_widget_test_reports_count_expand_warning \
   counts.i_code_review_merge_request_widget_test_reports_count_expand_failed \
   --dir=all
   ```

1. Modify each newly generated file to match the existing files for the merge request widget extension telemetry.
   - Find existing examples by doing a glob search, like: `metrics/**/*_i_code_review_merge_request_widget_*`
   - Roughly speaking, each file should have these values:
     1. `description` = A plain English description of this value. Review existing widget extension telemetry files for examples.
     1. `product_section` = `dev`
     1. `product_stage` = `create`
     1. `product_group` = `code_review`
     1. `introduced_by_url` = `'[your MR]'`
     1. `options.events` = (the event in the command from above that generated this file, like `i_code_review_merge_request_widget_test_reports_count_view`)
         - This value is how the telemetry events are linked to "metrics" so this is probably one of the more important values.
     1. `data_source` = `redis`
     1. `data_category` = `optional`
1. Generate known HLL events on the command line with the following command.
   Replace `test_reports` with your appropriate name slug.

   ```shell
   bundle exec rails generate gitlab:usage_metric_definition:redis_hll code_review \
   i_code_review_merge_request_widget_test_reports_view \
   i_code_review_merge_request_widget_test_reports_full_report_clicked \
   i_code_review_merge_request_widget_test_reports_expand \
   i_code_review_merge_request_widget_test_reports_expand_success \
   i_code_review_merge_request_widget_test_reports_expand_warning \
   i_code_review_merge_request_widget_test_reports_expand_failed \
   --class_name=RedisHLLMetric
   ```

1. Repeat step 6, but change the `data_source` to `redis_hll`.

1. Add each event (those listed in the command in step 7, replacing `test_reports`
   with the appropriate name slug) to the aggregate files:
    1. `config/metrics/counts_7d/{timestamp}_code_review_category_monthly_active_users.yml`
    1. `config/metrics/counts_7d/{timestamp}_code_review_group_monthly_active_users.yml`
    1. `config/metrics/counts_28d/{timestamp}_code_review_category_monthly_active_users.yml`
    1. `config/metrics/counts_28d/{timestamp}_code_review_group_monthly_active_users.yml`

### Add new events

If you are adding a new event to our known events, include the new event in the
`KNOWN_EVENTS` list in `lib/gitlab/usage_data_counters/merge_request_widget_extension_counter.rb`.

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

| Placeholder | Style                                   |
|-------------|-----------------------------------------|
| success     | `gl-font-weight-bold gl-text-green-500` |
| danger      | `gl-font-weight-bold gl-text-red-500`   |
| critical    | `gl-font-weight-bold gl-text-red-800`   |
| same        | `gl-font-weight-bold gl-text-gray-700`  |
| strong      | `gl-font-weight-bold`                   |
| small       | `gl-font-sm`                            |

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
