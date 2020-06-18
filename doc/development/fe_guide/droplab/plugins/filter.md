# Filter

`Filter` is a plugin that allows for filtering data that has been added
to the dropdown using a simple fuzzy string search of an input value.

## Usage

Add the `Filter` object to the plugins array of a `DropLab.prototype.init` or `DropLab.prototype.addHook` call.

- `Filter` requires a configuration value for `template`.
- `template` should be the key of the objects within your data array that you want to compare
  to the user input string, for filtering.

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

Above, the input string will be compared against the `test` key of the passed data objects.

Optionally you can set `filterFunction` to a function. This function will be used instead
of `Filter`'s built in string search. `filterFunction` is passed 2 arguments, the first
is one of the data objects, the second is the current input value.
