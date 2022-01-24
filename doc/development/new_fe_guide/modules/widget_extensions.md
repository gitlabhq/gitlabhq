---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Merge request widget extensions **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/44616) in GitLab 13.6.

## Summary

Extensions in the merge request widget enable you to add new features
into the widget that match the existing design and interaction as other extensions.

## Usage

To use extensions you need to first create a new extension object to fetch the
data to render in the extension. See the example file in
`app/assets/javascripts/vue_merge_request_widget/extensions/issues.js` for a working example.

The basic object structure is as below:

```javascript
export default {
  name: '',
  props: [],
  computed: {
    summary() {},
    statusIcon() {},
  },
  methods: {
    fetchCollapsedData() {},
    fetchFullData() {},
  },
};
```

By following the same data structure, each extension can follow the same registering structure,
but each extension can manage its data sources.

After creating this structure you need to register it. Registering the extension can happen at any
point _after_ the widget has been created.

To register a extension the following can be done:

```javascript
// Import the register method
import { registerExtension } from '~/vue_merge_request_widget/components/extensions';

// Import the new extension
import issueExtension from '~/vue_merge_request_widget/extensions/issues';

// Register the imported extension
registerExtension(issueExtension);
```

## Polling

To enable polling for an extension, an options flag needs to be present in the extension.
For example:

```javascript
export default {
  //...
  enablePolling: true
};
```

This flag tells the base component that we should poll the `fetchCollapsedData()`
defined in the extension. Polling stops if the response has data or if an error is present.

When writing the logic for `fetchCollapsedData()`, a complete Axios response must be returned
from the method, due to the polling utility needing data like polling headers.
Otherwise, polling does not work correctly.

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

## Fetching errors

If `fetchCollapsedData()` or `fetchFullData()` methods throw an error:

- The loading state of the extension is updated to `LOADING_STATES.collapsedError` and `LOADING_STATES.expandedError`
  respectively.
- The extensions header displays an error icon and updates the text to be either:
  - The text defined in `$options.i18n.error`.
  - "Failed to load" if `$options.i18n.error` is not defined.
- The error is sent to Sentry to log that it occurred.

To customise the error text, you need to add it to the `i18n` object in your extension:

```javascript
export default {
  //...
  i18n: {
    //...
    error: __('Your error text'),
  },
};
```
