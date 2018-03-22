# HTML style guide

## Buttons

<a name="button-type"></a><a name="1.1"></a>
- [1.1](#button-type) **Use button type** Button tags requires a `type` attribute according to the [W3C HTML specification][button-type-spec].

```
// bad
<button></button>

// good
<button type="button"></button>
```

<a name="button-role"></a><a name="1.2"></a>
- [1.2](#button-role) **Use button role for non buttons** If an HTML element has an onClick handler but is not a button, it should have `role="button"`. This is more [accessible][button-role-accessible].

```
// bad
<div onClick="doSomething"></div>

// good
<div role="button" onClick="doSomething"></div>
```

## Links

<a name="blank-links"></a><a name="2.1"></a>
- [2.1](#blank-links) **Use rel for target blank** Use `rel="noopener noreferrer"` whenever your links open in a new window i.e. `target="_blank"`. This prevents [the following][jitbit-target-blank] security vulnerability documented by JitBit

```
// bad
<a href="url" target="_blank"></a>

// good
<a href="url" target="_blank" rel="noopener noreferrer"></a>
```

<a name="fake-links"></a><a name="2.2"></a>
- [2.2](#fake-links) **Do not use fake links** Use a button tag if a link only invokes JavaScript click event handlers. This is more semantic.

```
// bad
<a class="js-do-something" href="#"></a>

// good
<button class="js-do-something" type="button"></button>
```

[button-type-spec]: https://www.w3.org/TR/2011/WD-html5-20110525/the-button-element.html#dom-button-type
[button-role-accessible]: https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/ARIA_Techniques/Using_the_button_role
[jitbit-target-blank]: https://www.jitbit.com/alexblog/256-targetblank---the-most-underestimated-vulnerability-ever/
