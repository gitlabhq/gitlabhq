---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Dark mode

This page is about developing dark mode for GitLab. For more information on how to enable dark mode, see [Profile preferences](../../user/profile/preferences.md#dark-mode).

## How dark mode works

1. The [color palette](https://design.gitlab.com/product-foundations/color) values are reversed using [dark mode design tokens](design_tokens.md#dark-mode-design-tokens) to provide darker colors for smaller scales.
1. `app/assets/stylesheets/themes/_dark.scss` imports [dark mode design token](design_tokens.md#dark-mode) SCSS variables for colors.
1. `app/assets/stylesheets/themes/dark_mode_overrides.scss` imports [dark mode design token](design_tokens.md#dark-mode) CSS custom properties for colors.
1. Bootstrap variables overridden in `app/assets/stylesheets/framework/variables_overrides.scss` are given dark mode values in `_dark.scss`.
1. `_dark.scss` is loaded _before_ `application.scss` to generate separate `application_dark.css` stylesheet for dark mode users only.

## SCSS variables vs CSS custom properties

Design tokens generate both SCSS variables and CSS custom properties which are imported into the dark mode stylesheet.

- **SCSS variables:** are used in framework, components, and utility classes and override existing color usage for dark mode.
- **CSS custom properties:** are used for any colors within the `app/assets/stylesheets/page_bundles` directory.

As we do not want to generate separate `*_dark.css` variants of every `page_bundle` file,
we use CSS custom properties with SCSS variables as fallbacks. This is because when we generate the `page_bundles`
CSS, we get the variable values from `_variables.scss`, so any SCSS variables have light mode values.

As the CSS custom properties defined in `_dark.scss` are available in the browser, they have the correct colors for dark mode.

```scss
color: var(--gray-500, $gray-500);
```

## Utility classes

We generate a separate `utilities_dark.css` file for utility classes containing the inverted values. So a class
such as `gl-text-white` specifies a text color of `#333` in dark mode. This means you do not have to
add multiple classes every time you want to add a color.

Currently, we cannot set up a utility class only in dark mode. We hope to address that
[issue](https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1141) soon.

## Using different values between light and dark mode

In most cases, we can use the same values for light and dark mode. If that is not possible, you
can add an override using the `.gl-dark` class that dark mode adds to `body`:

```scss
color: $gray-700;
.gl-dark & {
  color: var(--gray-500);
}
```

NOTE:
Avoid using a different value for the SCSS fallback

```scss
// avoid where possible
// --gray-500 (#999) in dark mode
// $gray-700 (#525252) in light mode
color: var(--gray-500, $gray-700);
```

We [plan to add](https://gitlab.com/groups/gitlab-org/-/epics/7400) the CSS variables to light mode. When that happens, different values for the SCSS fallback will no longer work.
