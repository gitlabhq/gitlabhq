---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Ajax plugin

`Ajax` is a DropLab plugin that allows for retrieving and rendering list data
from a server.

## Usage

Add the `Ajax` object to the plugins array of a `DropLab.prototype.init` or
`DropLab.prototype.addHook` call.

`Ajax` requires 2 configuration values: the `endpoint` and `method`.

- `endpoint`: Should be a URL to the request endpoint.
- `method`: Should be `setData` or `addData`.
- `setData`: Completely replaces the dropdown with the response data.
- `addData`: Appends the response data to the current dropdown list.

```html
<a href="#" id="trigger" data-dropdown-trigger="#list">Toggle</a>
<ul id="list" data-dropdown><!-- ... --><ul>
```

```javascript
const droplab = new DropLab();

const trigger = document.getElementById('trigger');
const list = document.getElementById('list');

droplab.addHook(trigger, list, [Ajax], {
  Ajax: {
    endpoint: '/some-endpoint',
    method: 'setData',
  },
});
```

Optionally, you can set `loadingTemplate` to a HTML string. This HTML string
replaces the dropdown list while the request is pending.

Additionally, you can set `onError` to a function to catch any XHR errors.
