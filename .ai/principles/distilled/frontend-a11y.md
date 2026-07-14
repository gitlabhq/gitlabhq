---
source_checksum: 22b6d121be07ec34
distilled_at_sha: 56d6e7df2193336003a2368db3b4c1ae9cb6f911
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

> **Prerequisite:** If you haven't already, also read .ai/principles/distilled/frontend-vue.md - it contains foundational rules that apply to all frontend work.

# Frontend Accessibility Principles

## Checklist

### Semantic HTML

- Prefer semantic HTML elements over `div`/`span` with ARIA roles (e.g., use `<button>` not `<div role="button">`, `<a>` not `<div role="link">`)
- DO NOT use `role` attributes when a native HTML element with the equivalent implicit role exists
- Replace `div`/`span` elements with semantic equivalents like `p`, `button`, `time`, `article`, `ol`/`ul`, `table`, etc.
- Ensure heading levels are not skipped and are nested correctly
- Ensure only one `h1` element exists per page

### Accessible Names

- Ensure every form input (`text`, `textarea`, `select`, `checkbox`, `radio`, `file`, `toggle`) has an associated `<label>`
- Ensure every button and link has visible text or an `aria-label` when no visible text is present
- Ensure every `<img>` has an `alt` attribute (empty `alt=""` for decorative images)
- Keep `alt` attribute text under approximately 150 characters
- Ensure `<fieldset>` has `<legend>` as its first child
- Ensure `<figure>` has `<figcaption>` as its first child
- Ensure `<table>` has `<caption>` as its first child
- Ensure every chart has both a short and a long description (per W3C complex image guidance)
- Ensure buttons and links have accessible names descriptive enough to be understood in isolation (e.g., "Submit review" not "Submit")
- Use `gl-sr-only` class to visually hide labels that must remain accessible to screen readers
- Know the accessible-name computation order the browser uses when several names are present (`aria-labelledby` → `aria-label` → `alt`/`legend`/`figcaption`/`caption` → `title`); this is the resolution order, not authoring advice — DO NOT add `aria-label` where a descriptive `alt` already provides the name

### Icons

- Ensure non-decorative icons (those conveying information) have an `aria-label`
- Ensure clickable icons use `<gl-button icon="..." />` not `<gl-icon />` with a click handler
- Ensure icon-only buttons have an `aria-label`
- DO NOT add `aria-hidden="true"` to `<gl-icon>` — it hides icons from screen readers by default
- Hide decorative images from screen readers using `alt=""` on `<img>`, or `role="img"` + `alt=""` on inline SVGs

### ARIA Usage

- DO NOT use `aria-*`, `role`, or `tabindex` when semantic HTML provides equivalent accessibility
- Use ARIA only for UI patterns without semantic HTML equivalents (e.g., modals, tabs, custom dropdowns)
- Ensure all custom ARIA widget patterns comply with WCAG

### Keyboard Navigation & Focus

- Ensure all interactive elements are reachable via <kbd>Tab</kbd> and have a visible focus state
- Ensure elements with tooltips are focusable via <kbd>Tab</kbd>
- When adding `:hover` styles, add matching `:focus` styles for keyboard users
- DO NOT remove an element's `outline` without providing an alternative visible focus indicator (e.g., `box-shadow`)
- Ensure <kbd>Tab</kbd> and <kbd>Shift-Tab</kbd> move only between interactive elements, not static content

### `tabindex`

- DO NOT use `tabindex="0"` on interactive elements (`<gl-link>`, `<gl-button>`) — they are already tab-accessible
- DO NOT use `tabindex="0"` on static/non-interactive elements just to make them readable by screen readers
- DO NOT use positive `tabindex` values (`tabindex="1"` or greater)
- DO NOT use `tabindex="0"` to make a `div`/`span` interactive — use a semantic interactive element instead

### Testing & Tooling

- Rely on the CI accessibility checks (Storybook tests use `axe-playwright` and run on Vue/JS changes, blocking merges on violations); the repository's `axe-linter.yml` maps Pajamas components to native HTML. Humans can additionally install the [axe Accessibility Linter](https://marketplace.visualstudio.com/items?itemName=deque-systems.vscode-axe-linter) VS Code plugin for real-time editor feedback.
- Add Storybook stories covering all component states for new Vue components and ensure Storybook accessibility tests pass before integration
- Include feature tests using `axe-core-gem` for complete user journeys covering HAML, Vue, and JS
- Use axe DevTools browser extension during code review to validate accessibility on any page
- For Vue/JS files: apply linting + Storybook tests + feature tests
- For HAML files: apply feature tests + browser extension (linting not supported)

## Authoritative sources

For the full picture, see:

- doc/development/fe_guide/accessibility/_index.md
- doc/development/fe_guide/accessibility/best_practices.md

