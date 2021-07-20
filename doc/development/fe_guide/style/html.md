---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# HTML style guide

See also our [accessibility page](../accessibility.md).

## Semantic elements

[Semantic elements](https://developer.mozilla.org/en-US/docs/Glossary/Semantics) are HTML tags that
give semantic (rather than presentational) meaning to the data they contain. For example:

- [`<article>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/article)
- [`<nav>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/nav)
- [`<strong>`](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/strong)

Prefer using semantic tags, but only if the intention is truly accurate with the semantic meaning
of the tag itself. View the [MDN documentation](https://developer.mozilla.org/en-US/docs/Web/HTML/Element)
for a description on what each tag semantically means.

```html
<!-- bad - could use semantic tags instead of div's. -->
<div class="...">
  <p>
    <!-- bad - this isn't what "strong" is meant for. -->
    Simply visit your <strong>Settings</strong> to say hello to the world.
  </p>
  <div class="...">...</div>
</div>

<!-- good - prefer semantic classes used accurately -->
<section class="...">
  <p>
    Simply visit your <span class="gl-font-weight-bold">Settings</span> to say hello to the world.
  </p>
  <footer class="...">...</footer>
</section>
```

## Buttons

### Button type

Button tags requires a `type` attribute according to the [W3C HTML specification](https://www.w3.org/TR/2011/WD-html5-20110525/the-button-element.html#dom-button-type).

```html
// bad
<button></button>

// good
<button type="button"></button>
```

## Links

### Blank target

Avoid forcing links to open in a new window as this reduces the control the user has over the link.
However, it might be a good idea to use a blank target when replacing the current page with
the link makes the user lose content or progress.

Use `rel="noopener noreferrer"` whenever your links open in a new window, that is, `target="_blank"`. This prevents a security vulnerability [documented by JitBit](https://www.jitbit.com/alexblog/256-targetblank---the-most-underestimated-vulnerability-ever/).

When using `gl-link`, using `target="_blank"` is sufficient as it automatically adds `rel="noopener noreferrer"` to the link.

```html
// bad
<a href="url" target="_blank"></a>

// good
<a href="url" target="_blank" rel="noopener noreferrer"></a>

// good
<gl-link href="url" target="_blank"></gl-link>
```

### Fake links

**Do not use fake links.** Use a button tag if a link only invokes JavaScript click event handlers, which is more semantic.

```html
// bad
<a class="js-do-something" href="#"></a>

// good
<button class="js-do-something" type="button"></button>
```
