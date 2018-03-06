# HTML style guide

## Buttons

<a name="button-type"></a><a name="1.1"></a>
- [1.1](#button-type) **Use button type** Button type is a required attribute for button tags according to the HTML specification.

```
// bad
<button></button>

// good
<button type="button"></button>
```

## Links

<a name="blank-links"></a><a name="2.1"></a>
- [2.1](#blank-links) **Use rel for target blank** Use `rel="noopener noreferrer"` whenever your links `target="_blank"`.
This prevents a security vulnerability documented by [JitBit][JitBit]

```
// bad
<a href="url" target="_blank"></a>

// good
<a href="url" target="_blank" rel="noopener noreferrer"></a>
```

<a name="fake-links"></a><a name="2.2"></a>
- [2.2](#fake-links) **Avoid using fake links** Buttons should be used if a link only invokes JavaScript click event handlers.

```
// bad
<a class="js-do-something" href="#"></a>

// good
<button class="js-do-something" type="button"></button>
```

[JitBit]: https://www.jitbit.com/alexblog/256-targetblank---the-most-underestimated-vulnerability-ever/
