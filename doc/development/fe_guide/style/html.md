---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: HTML style guide
---

See also our [accessibility best practices](../accessibility/best_practices.md).

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
    Simply visit your <span class="gl-font-bold">Settings</span> to say hello to the world.
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

Arbitrarily opening links in a new tab is not recommended, so refer to the [Pajamas guidelines on links](https://design.gitlab.com/components/link) when considering adding `target="_blank"` to links.

When using `target="_blank"` with `a` tags, you must also add the `rel="noopener noreferrer"` attribute. This prevents a security vulnerability [documented by JitBit](https://www.jitbit.com/alexblog/256-targetblank---the-most-underestimated-vulnerability-ever/).

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
