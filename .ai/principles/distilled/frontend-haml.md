---
source_checksum: be52dbdd1345dcbf
distilled_at_sha: 52964caf288c3d9936b8ce4a3d2242c1f92567fa
---
<!-- Auto-generated from docs.gitlab.com by gitlab-ai-principles-distiller — do not edit manually -->

> **Prerequisite:** If you haven't already, also read .ai/principles/distilled/frontend-vue.md - it contains foundational rules that apply to all frontend work.

# HTML & HAML Principles

## Checklist

### Semantic HTML

- Prefer semantic HTML tags (`<article>`, `<nav>`, `<section>`, `<footer>`, etc.) only when their semantic meaning accurately matches the content's intent.
- DO NOT use `<strong>` or other semantic tags for purely presentational purposes (e.g., bold styling); use CSS classes like `gl-font-bold` instead.
- DO NOT use `<div>` elements where semantic alternatives exist and are appropriate.

### Buttons

- Ensure every `<button>` element has an explicit `type` attribute (e.g., `type="button"`).
- DO NOT use fake links (`<a href="#">`) to invoke JavaScript handlers; use `<button type="button">` instead.

### Links

- DO NOT add `target="_blank"` to `<a>` tags without also adding `rel="noopener noreferrer"`.
- When using `gl-link` with `target="_blank"`, omit `rel="noopener noreferrer"` (it is added automatically).
- DO NOT arbitrarily open links in a new tab; follow the Pajamas guidelines on links before adding `target="_blank"`.

### HAML & Pajamas Components

- Prefer Pajamas ViewComponents over raw HTML/CSS when a ViewComponent exists for the UI element.
- Use the GitLab UI form builder (`gitlab_ui_form_for`) instead of standard `form_for` when building HAML forms with Pajamas-styled inputs.
- Replace `f.check_box` + `f.label` pairs with `f.gitlab_ui_checkbox_component` when using `gitlab_ui_form_for`.
- Use `gitlab_ui_radio_component` for radio buttons within `gitlab_ui_form_for` forms.
- Pass label content as the second argument to `gitlab_ui_checkbox_component`; use the `label` slot only when HTML content is required inside the label.
- Pass help text via the `help_text:` keyword argument to `gitlab_ui_checkbox_component`/`gitlab_ui_radio_component`; use the `help_text` slot only when HTML content is required.
- DO NOT use `f.label` as a separate element alongside `gitlab_ui_checkbox_component` or `gitlab_ui_radio_component`; the label is managed by the component itself.

## Authoritative sources

For the full picture, see:

- doc/development/fe_guide/style/html.md
- doc/development/fe_guide/haml.md

