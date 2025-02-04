---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Accessibility best practices
---

## Quick summary

Since [no ARIA is better than bad ARIA](https://w3c.github.io/aria-practices/#no_aria_better_bad_aria),
review the following recommendations before using `aria-*`, `role`, and `tabindex`.
Use semantic HTML, which has accessibility semantics baked in, and ideally test with
[relevant combinations of screen readers and browsers](https://www.accessibility-developer-guide.com/knowledge/screen-readers/relevant-combinations/).

In [WebAIM's accessibility analysis of the top million home pages](https://webaim.org/projects/million/#aria),
they found that "ARIA correlated to higher detectable errors".
It is likely that *misuse* of ARIA is a big cause of increased errors,
so when in doubt don't use `aria-*`, `role`, and `tabindex` and stick with semantic HTML.

## Enable keyboard navigation on macOS

By default, macOS limits the <kbd>tab</kbd> key to **Text boxes and lists only**. To enable full keyboard navigation:

1. Open **System Preferences**.
1. Select **Keyboard**.
1. Open the **Shortcuts** tab.
1. Enable the setting **Use keyboard navigation to move focus between controls**.

You can read more about enabling browser-specific keyboard navigation on [a11yproject](https://www.a11yproject.com/posts/macos-browser-keyboard-navigation/).

## Quick checklist

- [Text](https://design.gitlab.com/components/text-input#accessibility),
  [textarea](https://design.gitlab.com/components/textarea#accessibility),
  [select](https://design.gitlab.com/components/select#accessibility),
  [checkbox](https://design.gitlab.com/components/checkbox#accessibility),
  [radio](https://design.gitlab.com/components/radio-button#accessibility),
  [file](#file-inputs-with-accessible-names),
  and [toggle](https://design.gitlab.com/components/toggle#accessibility) inputs have accessible names.
- [Buttons](#buttons-and-links-with-descriptive-accessible-names),
  [links](#buttons-and-links-with-descriptive-accessible-names),
  and [images](#images-with-accessible-names) have descriptive accessible names.
- Icons
  - [Non-decorative icons](#icons-that-convey-information) have an `aria-label`.
  - [Clickable icons](#icons-that-are-clickable) are buttons, that is, `<gl-button icon="close" />` is used and not `<gl-icon />`.
  - Icon-only buttons have an `aria-label`.
- Interactive elements can be [accessed with the Tab key](#support-keyboard-only-use) and have a visible focus state.
- Elements with [tooltips](https://design.gitlab.com/components/tooltip#accessibility) are focusable using the Tab key.
- Are any `role`, `tabindex` or `aria-*` attributes unnecessary?
- Can any `div` or `span` elements be replaced with a more semantic [HTML element](https://developer.mozilla.org/en-US/docs/Web/HTML/Element) like `p`, `button`, or `time`?

## Provide a good document outline

[Headings are the primary mechanism used by screen reader users to navigate content](https://webaim.org/projects/screenreadersurvey8/#finding).
Therefore, the structure of headings on a page should make sense, like a good table of contents.
We should ensure that:

- There is only one `h1` element on the page.
- Heading levels are not skipped.
- Heading levels are nested correctly.

## Provide accessible names for screen readers

To provide markup with accessible names, ensure every:

- input has an [associated `label`](#examples-of-providing-accessible-names).
- button and link have [visible text](#buttons-and-links-with-descriptive-accessible-names), or `aria-label` when there is no visible text, such as for an icon button with no content.
- image has an [`alt` attribute](#images-with-accessible-names).
- `fieldset` has `legend` as its first child.
- `figure` has `figcaption` as its first child.
- `table` has `caption` as its first child.

Groups of checkboxes and radio inputs should be grouped together in a `fieldset` with a `legend`.
`legend` gives the group of checkboxes and radio inputs a label.

If the `label`, child text, or child element is not visually desired,
use `.gl-sr-only` to hide the element from everything but screen readers.

### Examples of providing accessible names

The following subsections contain examples of markup that render HTML elements with accessible names.

Note that [when using `GlFormGroup`](https://bootstrap-vue.org/docs/components/form-group#accessibility):

- Passing only a `label` prop renders a `fieldset` with a `legend` containing the `label` value.
- Passing both a `label` and a `label-for` prop renders a `label` that points to the form input with the same `label-for` ID.

#### File inputs with accessible names

File input examples:

```html
<!-- File input with a label -->
<label for="attach-file">{{ __('Attach a file') }}</label>
<input id="attach-file" type="file" />

<!-- File input with a hidden label -->
<label for="attach-file" class="gl-sr-only">{{ __('Attach a file') }}</label>
<input id="attach-file" type="file" />
```

#### Images with accessible names

Image examples:

```html
<img :src="imagePath" :alt="__('A description of the image')" />

<!-- SVGs implicitly have a graphics role so if it is semantically an image we should apply `role="img"` -->
<svg role="img" :alt="__('A description of the image')" />

<!-- A decorative image, hidden from screen readers -->
<img :src="imagePath" :alt="" />
```

#### Buttons and links with descriptive accessible names

Buttons and links should have accessible names that are descriptive enough to be understood in isolation.

```html
<!-- bad -->
<gl-button @click="handleClick">{{ __('Submit') }}</gl-button>

<gl-link :href="url">{{ __('page') }}</gl-link>

<!-- good -->
<gl-button @click="handleClick">{{ __('Submit review') }}</gl-button>

<gl-link :href="url">{{ __("GitLab's accessibility page") }}</gl-link>
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

Use semantic HTML, such as `a` (`GlLink`) and `button` (`GlButton`), which provides these behaviours by default.

Keep in mind that:

- <kbd>Tab</kbd> and <kbd>Shift-Tab</kbd> should only move between interactive elements, not static content.
- When you add `:hover` styles, in most cases you should add `:focus` styles too so that the styling is applied for both mouse **and** keyboard users.
- If you remove an interactive element's `outline`, make sure you maintain visual focus state in another way such as with `box-shadow`.

See the [Pajamas Keyboard-only page](https://design.gitlab.com/accessibility/keyboard-only) for more detail.

## `tabindex`

Prefer **no** `tabindex` to using `tabindex`, since:

- Using semantic HTML such as `button` (`GlButton`) implicitly provides `tabindex="0"`.
- Tabbing order should match the visual reading order and positive `tabindex`s interfere with this.

### Avoid using `tabindex="0"` to make an element interactive

Use interactive elements instead of `div` and `span` tags.
For example:

- If the element should be clickable, use a `button` (`GlButton`).
- If the element should be text editable, use an [`input`](https://design.gitlab.com/components/text-input#accessibility) or [`textarea`](https://design.gitlab.com/components/textarea#accessibility).

Once the markup is semantically complete, use CSS to update it to its desired visual state.

```html
<!-- bad -->
<div role="button" tabindex="0" @click="expand">Expand</div>

<!-- good -->
<gl-button class="gl-p-0!" category="tertiary" @click="expand">Expand</gl-button>
```

### Do not use `tabindex="0"` on interactive elements

Interactive elements are already tab accessible so adding `tabindex` is redundant.

```html
<!-- bad -->
<gl-link href="help" tabindex="0">Help</gl-link>
<gl-button tabindex="0">Submit</gl-button>

<!-- good -->
<gl-link href="help">Help</gl-link>
<gl-button>Submit</gl-button>
```

### Do not use `tabindex="0"` on elements for screen readers to read

Screen readers can read text that is not tab accessible.
The use of `tabindex="0"` is unnecessary and can cause problems,
as screen reader users then expect to be able to interact with it.

```html
<!-- bad -->
<p tabindex="0" :aria-label="message">{{ message }}</p>

<!-- good -->
<p>{{ message }}</p>
```

### Do not use a positive `tabindex`

[Always avoid using `tabindex="1"`](https://webaim.org/techniques/keyboard/tabindex#overview)
or greater.

## Icons

Icons can be split into three different types:

- Icons that are decorative
- Icons that convey meaning
- Icons that are clickable

### Icons that are decorative

Icons are decorative when there's no loss of information to the user when they are removed from the UI.

As the majority of icons within GitLab are decorative, `GlIcon` automatically hides its rendered icons from screen readers.
Therefore, you do not need to add `aria-hidden="true"` to `GlIcon`, as this is redundant.

```html
<!-- unnecessary — gl-icon hides icons from screen readers by default -->
<gl-icon name="rocket" aria-hidden="true" />

<!-- good -->
<gl-icon name="rocket" />
```

### Icons that convey information

Icons convey information if there is loss of information to the user when they are removed from the UI.

An example is a confidential icon that conveys the issue is confidential, and does not have the text "Confidential" next to it.

Icons that convey information must have an accessible name so that the information is conveyed to screen reader users too.

```html
<!-- bad -->
<gl-icon name="eye-slash" />

<!-- good -->
<gl-icon name="eye-slash" :aria-label="__('Confidential issue')" />
```

### Icons that are clickable

Icons that are clickable are semantically buttons, so they should be rendered as buttons, with an accessible name.

```html
<!-- bad -->
<gl-icon name="close" :aria-label="__('Close')" @click="handleClick" />

<!-- good -->
<gl-button icon="close" category="tertiary" :aria-label="__('Close')" @click="handleClick" />
```

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
<!-- good - decorative images hidden from screen readers -->

<img src="decorative.jpg" alt="">

<svg role="img" alt="" />

<gl-icon name="epic" />
```

## When to use ARIA

No ARIA is required when using semantic HTML, because it already incorporates accessibility.

However, there are some UI patterns that do not have semantic HTML equivalents.
General examples of these are dialogs (modals) and tabs.
GitLab-specific examples are assignee and label dropdowns.
Building such widgets require ARIA to make them understandable to screen readers.
Proper research and testing should be done to ensure compliance with [WCAG](https://www.w3.org/WAI/standards-guidelines/wcag/).
