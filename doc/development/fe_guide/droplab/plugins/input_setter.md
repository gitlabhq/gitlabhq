---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# InputSetter plugin

`InputSetter` is a DropLab plugin that allows for updating DOM out of the scope
of DropLab when a list item is clicked.

## Usage

Add the `InputSetter` object to the plugins array of a `DropLab.prototype.init`
or `DropLab.prototype.addHook` call.

- `InputSetter`: Requires a configuration value for `input` and `valueAttribute`.
- `input`: The DOM element that you want to manipulate.
- `valueAttribute`: A string that's the name of an attribute on your list items
  that's used to get the value to update the `input` element with.

You can also set the `InputSetter` configuration to an array of objects, which
allows you to update multiple elements.

```html
<input id="input" value="">
<div id="div" data-selected-id=""></div>

<input href="#" id="trigger" data-dropdown-trigger="#list">
<ul id="list" data-dropdown data-dynamic>
  <li><a href="#" data-id="{{id}}">{{text}}</a></li>
<ul>
```

```javascript
const droplab = new DropLab();

const trigger = document.getElementById('trigger');
const list = document.getElementById('list');

const input = document.getElementById('input');
const div = document.getElementById('div');

droplab.init(trigger, list, [InputSetter], {
  InputSetter: [{
    input: input,
    valueAttribute: 'data-id',
  } {
    input: div,
    valueAttribute: 'data-id',
    inputAttribute: 'data-selected-id',
  }],
});

droplab.addData('trigger', [{
  id: 0,
  text: 'Jacob',
}, {
  id: 1,
  text: 'Jeff',
}]);
```

In the previous code, if the second list item was clicked, it would update the
`#input` element to have a `value` of `1`, it would also update the `#div`
element's `data-selected-id` to `1`.

Optionally, you can set `inputAttribute` to a string that's the name of an
attribute on your `input` element that you want to update. If you don't provide
an `inputAttribute`, `InputSetter` updates the `value` of the `input`
element if it's an `INPUT` element, or the `textContent` of the `input` element
if it isn't an `INPUT` element.
