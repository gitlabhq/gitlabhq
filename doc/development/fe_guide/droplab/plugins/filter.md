---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Filter plugin

`Filter` is a DropLab plugin that allows for filtering data that has been added
to the dropdown using a simple fuzzy string search of an input value.

## Usage

Add the `Filter` object to the plugins array of a `DropLab.prototype.init` or
`DropLab.prototype.addHook` call.

- `Filter`: Requires a configuration value for `template`.
- `template`: Should be the key of the objects within your data array that you
  want to compare to the user input string, for filtering.

```html
<input href="#" id="trigger" data-dropdown-trigger="#list">
<ul id="list" data-dropdown data-dynamic>
  <li><a href="#" data-id="{{id}}">{{text}}</a></li>
<ul>
```

```javascript
const droplab = new DropLab();

const trigger = document.getElementById('trigger');
const list = document.getElementById('list');

droplab.init(trigger, list, [Filter], {
  Filter: {
    template: 'text',
  },
});

droplab.addData('trigger', [{
  id: 0,
  text: 'Jacob',
}, {
  id: 1,
  text: 'Jeff',
}]);
```

In the previous code, the input string is compared against the `test` key of the
passed data objects.

Optionally you can set `filterFunction` to a function. This function will be
used instead of `Filter`'s built-in string search. `filterFunction` is passed
two arguments: the first is one of the data objects, and the second is the
current input value.
