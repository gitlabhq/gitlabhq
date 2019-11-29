# HTML style guide

## Buttons

### Button type

Button tags requires a `type` attribute according to the [W3C HTML specification](https://www.w3.org/TR/2011/WD-html5-20110525/the-button-element.html#dom-button-type).

```html
// bad
<button></button>

// good
<button type="button"></button>
```

### Button role

If an HTML element has an `onClick` handler but is not a button, it should have `role="button"`. This is [more accessible](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Roles/button_role).

```html
// bad
<div onClick="doSomething"></div>

// good
<div role="button" onClick="doSomething"></div>
```

## Links

### Blank target

Use `rel="noopener noreferrer"` whenever your links open in a new window, i.e. `target="_blank"`. This prevents a security vulnerability [documented by JitBit](https://www.jitbit.com/alexblog/256-targetblank---the-most-underestimated-vulnerability-ever/).

```html
// bad
<a href="url" target="_blank"></a>

// good
<a href="url" target="_blank" rel="noopener noreferrer"></a>
```

### Fake links

**Do not use fake links.** Use a button tag if a link only invokes JavaScript click event handlers, which is more semantic.

```html
// bad
<a class="js-do-something" href="#"></a>

// good
<button class="js-do-something" type="button"></button>
```
