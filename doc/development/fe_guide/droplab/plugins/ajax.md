# Ajax

`Ajax` is a droplab plugin that allows for retrieving and rendering list data from a server.

## Usage

Add the `Ajax` object to the plugins array of a `DropLab.prototype.init` or `DropLab.prototype.addHook` call.

`Ajax` requires 2 configuration values, the `endpoint` and `method`.

- `endpoint` should be a URL to the request endpoint.
- `method` should be `setData` or `addData`.
- `setData` completely replaces the dropdown with the response data.
- `addData` appends the response data to the current dropdown list.

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

Optionally you can set `loadingTemplate` to a HTML string. This HTML string will
replace the dropdown list while the request is pending.

Additionally, you can set `onError` to a function to catch any XHR errors.
