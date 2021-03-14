---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Implementing keyboard shortcuts

We use [Mousetrap](https://craig.is/killing/mice) to implement keyboard
shortcuts in GitLab.

Mousetrap provides an API that allows keyboard shortcut strings (like
`mod+shift+p` or `p b`) to be bound to a JavaScript handler:

```javascript
// Don't do this; see note below
Mousetrap.bind('p b', togglePerformanceBar)
```

However, associating a hard-coded key sequence to a handler (as shown above)
prevents these keyboard shortcuts from being customized or disabled by users.

To allow keyboard shortcuts to be customized, commands are defined in
`~/behaviors/shortcuts/keybindings.js`. The `keysFor` method is responsible for
returning the correct key sequence for the provided command:

```javascript
import { keysFor, TOGGLE_PERFORMANCE_BAR } from '~/behaviors/shortcuts/keybindings'

Mousetrap.bind(keysFor(TOGGLE_PERFORMANCE_BAR), togglePerformanceBar);
```

## Shortcut customization

`keybindings.js` stores keyboard shortcut customizations as a JSON string in
`localStorage`. When `keysFor` is called, it uses the provided command object's
`id` to lookup any customizations found in `localStorage` and returns the custom
keybindings, or the default keybindings if the command has not been customized.
There is no UI to edit these customizations.

## Adding new shortcuts

Because keyboard shortcuts can be customized or disabled by end users,
developers are encouraged to build _lots_ of keyboard shortcuts into GitLab.
Shortcuts that are less likely to be used should be
[disabled](#disabling-shortcuts) by default.

To add a new shortcut, define and export a new command object in
`keybindings.js`:

```javascript
export const MAKE_COFFEE = {
  id: 'foodAndBeverage.makeCoffee',
  description: s__('KeyboardShortcuts|Make coffee'),
  defaultKeys: ['mod+shift+c'],
};
```

Next, add a new command to the appropriate keybinding group object:

```javascript
const COFFEE_GROUP = {
  id: 'foodAndBeverage',
  name: s__('KeyboardShortcuts|Food and Beverage'),
  keybindings: [
    MAKE_ESPRESSO,
    MAKE_LATTE,
    MAKE_COFFEE
  ];
}
```

Finally, in the application code, import the `keysFor` function and the new
command object and bind the shortcut to the handler using Mousetrap:

```javascript
import { keysFor, MAKE_COFFEE } from '~/behaviors/shortcuts/keybindings'

Mousetrap.bind(keysFor(MAKE_COFFEE), makeCoffee);
```

See the existing the command definitions in `keybindings.js` for more examples.

## Disabling shortcuts

A shortcut can be disabled, also known as _unassigned_, by assigning the
shortcut to an empty array `[]`. For example, to introduce a new shortcut that
is disabled by default, a command can be defined like this:

```javascript
export const MAKE_MOCHA = {
  id: 'foodAndBeverage.makeMocha',
  description: s__('KeyboardShortcuts|Make a mocha'),
  defaultKeys: [],
};
```

## Making shortcuts non-customizable

Occasionally, it's important that a keyboard shortcut _not_ be customizable
(although this should be a rare occurrence).

In this case, a shortcut can be defined with `customizable: false`, which
disables customization of the keybinding:

```javascript
export const MAKE_AMERICANO = {
  id: 'foodAndBeverage.makeAmericano',
  description: s__('KeyboardShortcuts|Make an Americano'),
  defaultKeys: ['mod+shift+a'],

  // this disables customization of this shortcut
  customizable: false
};
```

This shortcut will always be bound to its `defaultKeys`.

## Make cross-platform shortcuts

It's difficult to make shortcuts that work well in all platforms and browsers.
This is one of the reasons that being able to customize and disable shortcuts is
so important.

One important way to make keyboard shortcuts more portable is to use the `mod`
shortcut string, which resolves to `command` on Mac and `ctrl` otherwise.

See [Mousetrap's documentation](https://craig.is/killing/mice#api.bind.combo)
for more information.
