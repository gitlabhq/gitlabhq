---
type: reference, dev
stage: none
group: Development
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

This page is about developing dark mode for GitLab. We also have documentation on how
[to enable dark mode](../../user/profile/preferences.md#dark-mode).

# How dark mode works

Short version: Reverse the color palette and override a few Bootstrap variables.

Note the following:

- The dark mode palette is defined in `app/assets/stylesheets/themes/_dark.scss`.
  This is loaded _before_ application.scss to generate `application_dark.css`
  - We define two types of variables in `_dark.scss`:
    - SCSS variables are used in framework, components, and utility classes.
    - CSS variables are used for any colors within the `app/assets/stylesheets/page_bundles` directory.
- `app/views/layouts/_head.html.haml` then loads application or application_dark based on the user's theme preference.

As we do not want to generate separate `_dark.css` variants of every page_bundle file,
we use CSS variables with SCSS variables as fallbacks. This is because when we generate the `page_bundles`
CSS, we get the variable values from `_variables.scss`, so any SCSS variables have light mode values.

As the CSS variables defined in `_dark.scss` are available in the browser, they have the
correct colors for dark mode.

```scss
color: var(--gray-500, $gray-500);
```

## Utility classes

We generate a separate `utilities_dark.css` file for utility classes containing the inverted values. So a class
such as `gl-text-white` specifies a text color of `#333` in dark mode. This means you do not have to
add multiple classes every time you want to add a color.

Currently, we cannot set up a utility class only in dark mode. We hope to address that
[issue](https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1141) soon.

## Using different values in light and dark mode

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

We [plan to add](https://gitlab.com/gitlab-org/gitlab/-/issues/301147) the CSS variables to light mode. When that happens, different values for the SCSS fallback will no longer work.

## When to use SCSS variables

There are a few things we do in SCSS that we cannot (easily) do with CSS, such as the following
functions:

- `lighten`
- `darken`
- `color-yiq` (color contrast)

If those are needed then SCSS variables should be used.
