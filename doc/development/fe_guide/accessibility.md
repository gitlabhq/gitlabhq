---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Accessibility

Accessibility is important for users who use screen readers or rely on keyboard-only functionality
to ensure they have an equivalent experience to sighted mouse users.

This page contains guidelines we should follow.

## Quick summary

Since [no ARIA is better than bad ARIA](https://www.w3.org/TR/wai-aria-practices/#no_aria_better_bad_aria),
review the following recommendations before using `aria-*`, `role`, and `tabindex`.
Use semantic HTML, which typically has accessibility semantics baked in, but always be sure to test with
[relevant combinations of screen readers and browsers](https://www.accessibility-developer-guide.com/knowledge/screen-readers/relevant-combinations/).

In [WebAIM's accessibility analysis of the top million home pages](https://webaim.org/projects/million/#aria),
they found that "ARIA correlated to higher detectable errors".
It is likely that *misuse* of ARIA is a big cause of increased errors,
so when in doubt don't use `aria-*`, `role`, and `tabindex`, and stick with semantic HTML.

## Provide accessible names to screen readers

To provide markup with accessible names, ensure every:

- `input` has an associated `label`.
- `button` and `a` have child text, or `aria-label` when text isn't present.
  For example, an icon button with no visible text.
- `img` has an `alt` attribute.
- `fieldset` has `legend` as its first child.
- `figure` has `figcaption` as its first child.
- `table` has `caption` as its first child.

If the `label`, child text, or child element is not visually desired,
use `.gl-sr-only` to hide the element from everything but screen readers.

Ensure the accessible name is descriptive enough to be understood in isolation.

```html
// bad
<button>Submit</button>
<a href="url">page</a>

// good
<button>Submit review</button>
<a href="url">GitLab's accessibility page</a>
```

## Role

In general, avoid using `role`.
Use semantic HTML elements that implicitly have a `role` instead.

| Bad | Good |
| --- | --- |
| `<div role="button">` | `<button>` |
| `<div role="img">` | `<img>` |
| `<div role="link">` | `<a>` |
| `<div role="header">` | `<h1>` to `<h6>` |
| `<div role="textbox">` | `<input>` or `<textarea>` |
| `<div role="article">` | `<article>` |
| `<div role="list">` | `<ol>` or `<ul>` |
| `<div role="listitem">` | `<li>` |
| `<div role="table">` | `<table>` |
| `<div role="rowgroup">` | `<thead>`, `<tbody>`, or `<tfoot>` |
| `<div role="row">` | `<tr>` |
| `<div role="columnheader">` | `<th>` |
| `<div role="cell">` | `<td>` |

## Support keyboard-only use

Keyboard users rely on focus outlines to understand where they are on the page. Therefore, if an
element is interactive you must ensure:

- It can receive keyboard focus.
- It has a visible focus state.

Use semantic HTML, such as `a` and `button`, which provides these behaviours by default.

See the [Pajamas Keyboard-only page](https://design.gitlab.com/accessibility-audits/2-keyboard-only/) for more detail.

## Tabindex

Prefer **no** `tabindex` to using `tabindex`, since:

- Using semantic HTML such as `button` implicitly provides `tabindex="0"`
- Tabbing order should match the visual reading order and positive `tabindex`s interfere with this

### Avoid using `tabindex="0"` to make an element interactive

Use interactive elements instead of `div`s and `span`s.
For example:

- If the element should be clickable, use a `button`
- If the element should be text editable, use an `input` or `textarea`

Once the markup is semantically complete, use CSS to update it to its desired visual state.

```html
// bad
<div role="button" tabindex="0" @click="expand">Expand</div>

// good
<button @click="expand">Expand</button>
```

### Do not use `tabindex="0"` on interactive elements

Interactive elements are already tab accessible so adding `tabindex` is redundant.

```html
// bad
<a href="help" tabindex="0">Help</a>
<button tabindex="0">Submit</button>

// good
<a href="help">Help</a>
<button>Submit</button>
```

### Do not use `tabindex="0"` on elements for screen readers to read

Screen readers can read text that is not tab accessible.
The use of `tabindex="0"` is unnecessary and can cause problems,
as screen reader users then expect to be able to interact with it.

```html
// bad
<span tabindex="0" :aria-label="message">{{ message }}</span>

// good
<p>{{ message }}</p>
```

### Do not use a positive `tabindex`

[Always avoid using `tabindex="1"`](https://webaim.org/techniques/keyboard/tabindex#overview)
or greater.

## Hiding elements

Use the following table to hide elements from users, when appropriate.

| Hide from sighted users | Hide from screen readers | Hide from both sighted and screen reader users |
| --- | --- | --- |
| `.gl-sr-only` | `aria-hidden="true"` | `display: none`, `visibility: hidden`, or `hidden` attribute |

### Hide decorative images from screen readers

To reduce noise for screen reader users, hide decorative images using `alt=""`.
If the image is not an `img` element, such as an inline SVG, you can hide it by adding both `role="img"` and `alt=""`.

`gl-icon` components automatically hide their icons from screen readers so `aria-hidden="true"` is
unnecessary when using `gl-icon`.

```html
// good - decorative images hidden from screen readers
<img src="decorative.jpg" alt="">
<svg role="img" alt="">
<gl-icon name="epic"/>
```

## When should ARIA be used

No ARIA is required when using semantic HTML because it incorporates accessibility.

However, there are some UI patterns and widgets that do not have semantic HTML equivalents.
Building such widgets require ARIA to make them understandable to screen readers.
Proper research and testing should be done to ensure compliance with ARIA.

Ideally, these widgets would exist only in [GitLab UI](https://gitlab-org.gitlab.io/gitlab-ui/).
Use of ARIA would then only occur in [GitLab UI](https://gitlab.com/gitlab-org/gitlab-ui/) and not [GitLab](https://gitlab.com/gitlab-org/gitlab/).

## Resources

### Viewing the browser accessibility tree

- [Firefox DevTools guide](https://developer.mozilla.org/en-US/docs/Tools/Accessibility_inspector#accessing_the_accessibility_inspector)
- [Chrome DevTools guide](https://developers.google.com/web/tools/chrome-devtools/accessibility/reference#pane)

### Browser extensions

We have two options for Web accessibility testing:

- [axe](https://www.deque.com/axe/) for [Firefox](https://addons.mozilla.org/en-US/firefox/addon/axe-devtools/)
- [axe](https://www.deque.com/axe/) for [Chrome](https://chrome.google.com/webstore/detail/axe-devtools-web-accessib/lhdoppojpmngadmnindnejefpokejbdd)

### Other links

- [The A11Y Project](https://www.a11yproject.com/) is a good resource for accessibility
- [Awesome Accessibility](https://github.com/brunopulis/awesome-a11y)
  is a compilation of accessibility-related material
- You can read [Chrome Accessibility Developer Tools'](https://github.com/GoogleChrome/accessibility-developer-tools)
  rules on its [Audit Rules page](https://github.com/GoogleChrome/accessibility-developer-tools/wiki/Audit-Rules)
