---
stage: Create
group: Code Review
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
description: 'Developer documentation for extending the merge request report widget with additional features.'
title: Merge request widgets
---

Merge request widgets enable you to add new features that match the design framework.
With these widgets we get a lot of benefits out of the box without much effort required, like:

- A consistent look and feel.
- Tracking when the widget is opened.
- Virtual scrolling for performance.

## Usage

The widgets are regular Vue components that make use of the
`~/vue_merge_request_widget/components/widget/widget.vue` component.
Depending on the complexity of the use case, it is possible to pass down
configuration objects, or extend the component through `slot`s.

For an example that uses slots, refer to the following file:
`ee/app/assets/javascripts/vue_merge_request_widget/widgets/security_reports/mr_widget_security_reports.vue`

For an example that uses data objects, refer to the following file:
`ee/app/assets/javascripts/vue_merge_request_widget/widgets/metrics/index.vue`

Here is a minimal example that renders a Hello World widget:

```vue
<script>
import MrWidget from '~/vue_merge_request_widget/components/widget/widget.vue';
import { __ } from '~/locale';

export default {
  name: 'WidgetHelloWorld',
  components: {
    MrWidget,
  },
  computed: {
    summary() {
      return { title: __('Hello World') };
    },
  },
};
</script>
<template>
  <mr-widget :summary="summary" :is-collapsible="false" :widget-name="$options.name" />
</template>
```

### Registering widgets

The example above won't be rendered anywhere in the page. In order to mount it in the Merge Request
Widget section, we have to register the widget in one or both of these two locations:

- `app/assets/javascripts/vue_merge_request_widget/components/widget/app.vue` (for CE widgets)
- `ee/app/assets/javascripts/vue_merge_request_widget/components/widget/app.vue` (for CE and EE widgets)

Defining the component in the components list and adding the name to the `widgets` computed property
will mount the widget:

```vue
<script>
export default {
  components: {
    MrHelloWorldWidget: () =>
      import('ee/vue_merge_request_widget/widgets/hello_world/index.vue'),
  },
  computed: {
    mrHelloWorldWidget() {
      return this.mr.shouldRenderHelloWorldWidget ? 'MrHelloWorldWidget' : undefined;
    },
    widgets() {
      return [
        this.mrHelloWorldWidget,
      ].filter((w) => w);
    },
  },
};
</script>
```

## Data fetching

To fetch data when the widget is mounted, pass the `:fetch-collapsed-data` property a function
that performs an API call.

WARNING:
The function must return a `Promise` that resolves to the `response` object.
The implementation relies on the `POLL-INTERVAL` header to keep polling, therefore it is
important not to alter the status code and headers.

```vue
<script>
export default {
  // ...
  data() {
    return {
      collapsedData: [],
    };
  },
  methods: {
    fetchCollapsedData() {
      return axios.get('/my/path').then((response) => {
        this.collapsedData = response.data;
        return response;
      });
    },
  },
};
</script>
<template>
  <mr-widget :fetch-collapsed-data="fetchCollapsedData" />
</template>
```

`:fetch-expanded-data` works the same way, but it will be called only when the user expands the widget.

### Data structure

The `content` and `summary` properties can be used to render the `Widget`. Below is the documentation for both
properties:

```javascript
// content
{
  text: '',           // Required: Main text for the row
  subtext: '',        // Optional: Smaller sub-text to be displayed below the main text
  supportingText: '', // Optional: Paragraph to be displayed below the subtext
  icon: {             // Optional: Icon object
    name: EXTENSION_ICONS.success, // Required: The icon name for the row
  },
  badge: {            // Optional: Badge displayed after text
    text: '',         // Required: Text to be displayed inside badge
    variant: '',      // Optional: GitLab UI badge variant, defaults to info
  },
  link: {             // Optional: Link to a URL displayed after text
    text: '',         // Required: Text of the link
    href: '',         // Optional: URL for the link
  },
  actions: [],        // Optional: Action button for row
  children: [],       // Optional: Child content to render, structure matches the same structure
  helpPopover: {      // Optional: If provided, an information icon will be display at the right-most corner of the content row
    options: {
      title: ''       // Required: The title of the popover
    },
    content: {
      text: '',           // Optional: Text content of the popover
      learnMorePath: '',  // Optional: The path to the documentation. A learn more link will be displayed if provided.
    }
  }
}

// summary
{
  title: '',    // Required: The main text of the summary part
  subtitle: '', // Optional: The subtext of the summary part
}
```

### Errors

If `:fetch-collapsed-data` or `:fetch-expanded-data` methods throw an error.
To customise the error text, you can use the `:error-text` property:

```vue
<template>
  <mr-widget :error-text="__('Failed to load.')" />
</template>
```

## Telemetry

The base implementation of the widget framework includes some telemetry events.
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
1. Add the new widget name slug to `lib/gitlab/usage_data_counters/merge_request_widget_counter.rb`
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

## Demo

Visit [GitLab MR Widgets Demo](https://gitlab.com/gitlab-org/frontend/playground/gitlab-mr-widgets-demo/-/merge_requests/26) to
see an example of all widgets displayed together.
