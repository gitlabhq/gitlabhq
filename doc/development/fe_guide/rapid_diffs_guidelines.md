---
stage: AI Coding
group: Code Review
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Rapid Diffs guidelines
---

These guidelines apply to every change to Rapid Diffs. For the architecture
and how to add features, see [Rapid Diffs](rapid_diffs.md).

Before writing code, review the
[design principles](rapid_diffs.md#design-principles).

## Caching

Each `<diff-file>` fragment must produce identical HTML for every user viewing
the same diff so the server can cache and reuse the fragment.

- Diff file components like `DiffFileComponent`, viewers, and headers must only
  depend on diff content: the content SHA, file paths, line content, line
  numbers, and viewer name.
- Place user-specific data such as permissions, preferences, and avatar URLs in
  `data-app-data` on the root element, not inside individual diff files.
- Do not include request-specific data such as CSRF tokens or session state in
  diff file HTML.
- If a feature requires per-user content inside a diff file, such as discussion
  threads, load the content on the client after mount.
- When adding a property to a `ViewComponent`, check whether the value changes
  per user. If the value changes, the property does not belong in the diff file
  template.

## Client-server separation

- Render a feature on the server if the feature produces the same HTML for every
  user viewing the same diff. For example, syntax-highlighted code lines, hunk
  headers, and file headers are server-rendered. Handle a feature on the client
  through an adapter if the feature reacts to user input or varies per user.
  For example, inline discussions, file collapse toggle, options menu, and
  line permalink rewriting are client-side.
- Place global configuration in `data-app-data`, per-file metadata in
  `data-file-data`, and small element-specific values in individual `data-*`
  attributes. See
  [Data flow to the client](rapid_diffs.md#data-flow-to-the-client) for the
  full reference.
- Do not add latency between navigation and the first visible diff. If a change
  adds cost to the critical path, defer or eliminate the cost.

## HTML and styling

- Do not use Tailwind utility classes inside diff file templates. A single diff
  line with Tailwind classes can be 3-5x larger than one using a short `rd-`
  class name. Over thousands of lines, this difference is significant.
- Do not embed JSON blobs inside diff file bodies. Use `data-file-data` on the
  `<diff-file>` element, which is parsed once, and `data-*` attributes on
  specific elements for small values.
- Avoid deeply nested wrapper elements. Each extra `<div>` multiplied across
  thousands of lines adds measurable overhead to parse time and memory.
- Prefix all CSS classes with `rd-` to avoid conflicts with legacy styles.
- Avoid inline styles. Define styles in SCSS page bundles.
- Avoid deeply nested selectors. Prefer single-level class definitions.
- Use CSS variables for page-specific offsets like sticky headers and sidebar
  widths. Define them in page bundles, not in component styles.

## Adapters and runtime

- Do not attach listeners to individual elements. Use delegated `clicks`
  handlers or adapter lifecycle events.
- Defer non-essential work to after the critical rendering path. Use
  `VISIBLE`/`INVISIBLE` handlers for work that applies once the file is visible.
- Mount complex components on first user interaction, not ahead of time.
- Store intermediate state in `this.sink`, not in closures. Closures that
  capture large DOM references cause memory leaks.
- Clean up all event listeners and DOM references in `onUnmounted`. If you store
  a DOM reference outside the adapter, such as in a Pinia store or a Vue
  component, clear the reference in `onUnmounted` as well. Failing to do so
  keeps the detached DOM tree in memory.

```javascript
[MOUNTED](onUnmounted) {
  const handler = () => { /* ... */ };
  this.diffElement.addEventListener('input', handler);
  onUnmounted(() => {
    this.diffElement.removeEventListener('input', handler);
  });
},
```

## Accessibility

Rapid Diffs must conform to level AA of the
[WCAG 2.1](https://www.w3.org/TR/WCAG21/) and
[ATAG 2.0](https://www.w3.org/TR/ATAG20/) guidelines.

- Provide text alternatives for non-text diff content such as images.
- Make all interactive elements operable by keyboard. File toggles, expand
  controls, discussion threads, and option menus must not require a mouse.
- Use semantic HTML and proper heading hierarchy so assistive technology users
  can navigate between files, hunks, and discussions.
- Preserve user preferences like view mode, whitespace settings, and file
  browser visibility across sessions.
- Follow [the Pajamas accessibility developer checklist](https://design.gitlab.com/accessibility/evaluation).
