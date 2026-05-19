---
source_checksum: ddd3c634219676db
distilled_at_sha: 52964caf288c3d9936b8ce4a3d2242c1f92567fa
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

> **Prerequisite:** If you haven't already, also read .ai/principles/distilled/frontend-vue.md - it contains foundational rules that apply to all frontend work.

# Frontend SCSS Principles

## Checklist

### Utility Classes

- Prefer Tailwind CSS utility classes over adding new CSS to reduce CSS bundle growth.
- DO NOT use deprecated classes from `common.scss` that use non-design-system values.
- DO NOT use Bootstrap utility classes.
- Use `gl-`-prefixed Tailwind classes (e.g., `gl-mt-5`, `gl-text-subtle`).
- Add utility classes directly in HTML rather than combining them with custom styles in SCSS component classes.
- Use `@apply` in SCSS only when utility classes cannot be applied directly in HTML; prefer it for design-system-dependent properties (e.g., `margin`, `padding`).
- DO NOT combine utility classes and custom styles in a single component class unless absolutely necessary.
- Update `tailwind.defaults.js` in GitLab UI when a needed utility is not available, rather than writing custom CSS.

### Component Classes

- Create component classes only when composing utility classes removes duplication and encapsulates a clear responsibility.
- Prefer design-centered class names (e.g., `.button`, `.alert`) over domain-centered names (e.g., `.security-report-widget`).

### Responsive Design

- Use CSS container queries (mobile-first, min-width) instead of media queries.
- DO NOT use desktop-first max-width media queries (e.g., `max-lg:gl-mt-3` as the default).
- Use `@max-*:gl-hidden` on components instead of `gl-hidden` + overriding `display` on larger containers, to avoid assuming the component's internal display value.
- Use `@apply gl-mt-3 @lg:gl-mt-5` pattern in SCSS component classes for responsive styles.
- Use `scripts/frontend/migrate_to_container_queries.mjs` when migrating existing media queries to container queries.

### Dark Mode

- Use Tailwind classes or `@apply` with design token classes (e.g., `gl-text-subtle`) for dark mode color support.
- Prefer CSS custom properties over SCSS variables for color mode support.
- Use CSS custom properties (not SCSS variables) for any colors within `page_bundles` stylesheets.
- Create bespoke CSS custom properties only when design tokens cannot be used with Tailwind utilities or existing custom properties.

### Naming

- Use `snake_case` for SCSS filenames.
- Use `lowercase-hyphenated` format for CSS class names (not `snake_case` or `camelCase`).
- DO NOT create compound class names using SCSS `&` concatenation (e.g., `&-name`); write out full class names.
- Use class selectors instead of tag name selectors.
- Use class selectors instead of ID selectors.

### Nesting

- DO NOT nest SCSS unnecessarily; avoid extra specificity from wrapper components.

### Selectors

- DO NOT use selectors prefixed with `js-` for styling purposes.
- DO NOT concatenate strings to create class names in SCSS.
- DO NOT use utility CSS classes (e.g., `gl-mb-5`) as selectors in stylesheets.
- DO NOT use ARIA attribute selectors (e.g., `[aria-expanded=false]`) for styling; use state classes like `.is-collapsed` instead.

### Prohibited Patterns

- DO NOT use the SCSS `@extend` at-rule (causes memory leaks and does not work as intended).

### Linting

- Run `yarn lint:stylelint` to check for style guide violations before submitting.

### Pajamas CSS Overrides

- Flag excessive CSS overrides on Pajamas components (multiple class overrides changing borders, backgrounds, padding, or other default styling)
- Flag hardcoded color values, spacing values, or typography that should use design tokens
- Flag fixed type scales (e.g., `gl-text-700-fixed`) used outside of Markdown contexts

## Authoritative sources

For the full picture, see:

- doc/development/fe_guide/style/_index.md
- doc/development/fe_guide/style/scss.md
- doc/development/fe_guide/dark_mode.md

