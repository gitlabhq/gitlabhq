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
