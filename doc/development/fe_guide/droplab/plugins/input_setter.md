# InputSetter

`InputSetter` is a plugin that allows for updating DOM out of the scope of droplab when a list item is clicked.

## Usage

Add the `InputSetter` object to the plugins array of a `DropLab.prototype.init` or `DropLab.prototype.addHook` call.

* `InputSetter` requires a config value for `input` and `valueAttribute`.
* `input` should be the DOM element that you want to manipulate.
* `valueAttribute` should be a string that is the name of an attribute on your list items that is used to get the value
to update the `input` element with.

You can also set the `InputSetter` config to an array of objects, which will allow you to update multiple elements.


```html
<input id="input" value="">
<div id="div" data-selected-id=""></div>

<input href="#" id="trigger" data-dropdown-trigger="#list">
<ul id="list" data-dropdown data-dynamic>
  <li><a href="#" data-id="{{id}}">{{text}}</a></li>
<ul>
```
```js
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

Above, if the second list item was clicked, it would update the `#input` element
to have a `value` of `1`, it would also update the `#div` element's `data-selected-id` to `1`.

Optionally you can set `inputAttribute` to a string that is the name of an attribute on your `input` element that you want to update.
If you do not provide an `inputAttribute`, `InputSetter` will update the `value` of the `input` element if it is an `INPUT` element,
or the `textContent` of the `input` element if it is not an `INPUT` element.
