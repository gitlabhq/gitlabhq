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
This prevents a security vulnerability documented by [JitBit](https://www.jitbit.com/alexblog/256-targetblank---the-most-underestimated-vulnerability-ever/)

```
// bad
<a href="url" target="_blank"></a>

// good
<a href="url" target="_blank" rel="noopener noreferrer"></a>
```
