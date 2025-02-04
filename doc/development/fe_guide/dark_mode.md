---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Dark mode
---

This page is about developing dark mode for GitLab. For more information on how to enable dark mode, see [Profile preferences](../../user/profile/preferences.md#dark-mode).

## How dark mode works

### Current approach

1. GitLab UI includes light and dark mode [design tokens](https://gitlab.com/gitlab-org/gitlab-ui/-/blob/main/doc/contributing/design_tokens.md) CSS custom properties for colors and components.
1. [Semantic design tokens](https://design.gitlab.com/product-foundations/design-tokens#semantic-design-tokens) provide values for light and dark mode in general usage, for example: background, text, and border colors.

### Legacy approach

1. SCSS variables for the [color palette](https://design.gitlab.com/product-foundations/color) are reversed using [design tokens](https://gitlab.com/gitlab-org/gitlab-ui/-/blob/main/doc/contributing/design_tokens.md) to provide darker colors for smaller scales.
1. `app/assets/stylesheets/color_modes/_dark.scss` imports dark mode [design tokens](https://gitlab.com/gitlab-org/gitlab-ui/-/blob/main/doc/contributing/design_tokens.md) SCSS variables for colors.
1. Bootstrap variables overridden in `app/assets/stylesheets/framework/variables_overrides.scss` are given dark mode values in `_dark.scss`.
1. `_dark.scss` is loaded _before_ `application.scss` to generate separate `application_dark.css` stylesheet for dark mode users only.

## Utility classes

Design tokens for dark mode can be applied with Tailwind classes (`gl-text-subtle`) or with `@apply` rule (`@apply gl-text-subtle`).

## CSS custom properties vs SCSS variables

Design tokens generate both CSS custom properties and SCSS variables which are imported into the dark mode stylesheet.

- **CSS custom properties:** are preferred to update color modes without loading a color mode specific stylesheet, and are required for any colors within the `app/assets/stylesheets/page_bundles` directory.
- **SCSS variables:** override existing color usage for dark mode and are compiled into a color mode specific stylesheet.

### Page bundles

To support dark mode CSS custom properties should be used in `page_bundle` styles as we do not generate separate
`*_dark.css` variants of each `page_bundle` file.
