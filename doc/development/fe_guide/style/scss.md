---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# SCSS style guide

## Utility Classes

NOTE:
Please do not use any utilities that are prefixed with `gl-deprecated-`, instead use a Tailwind utility.

In order to reduce the generation of more CSS as our site grows, prefer the use of utility classes over adding new CSS. In complex cases, CSS can be addressed by adding component classes.

### Tailwind CSS

We are in the process of migrating our CSS utility class setup to [Tailwind CSS](https://tailwindcss.com/).
See the [Tailwind CSS blueprint](../../../architecture/blueprints/tailwindcss/index.md) for motivation, proposal,
and implementation details.

#### Building the Tailwind CSS bundle

When using Vite or Webpack with the GitLab Development Kit, Tailwind CSS watches for file changes to
build detected utilities on the fly.

To build a fresh Tailwind CSS bundle, run `yarn tailwindcss:build`. This is the script that gets
called internally when building production assets with `bundle exec rake gitlab:assets:compile`.

However the bundle gets built, the output is saved to `app/assets/builds/tailwind.css`.

### Where are utility classes defined?

Prefer the use of [utility classes defined in GitLab UI](https://gitlab.com/gitlab-org/gitlab-ui/-/blob/main/doc/css.md#utilities).

<!-- vale gitlab.Spelling = NO -->

An easy list of classes can also be [seen on Unpkg](https://unpkg.com/browse/@gitlab/ui/src/scss/utilities.scss).

<!-- vale gitlab.Spelling = YES -->

Or using an extension like [CSS Class completion](https://marketplace.visualstudio.com/items?itemName=Zignd.html-css-class-completion).

Classes in [`utilities.scss`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/stylesheets/utilities.scss) and [`common.scss`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/stylesheets/framework/common.scss) are being deprecated.
Classes in [`common.scss`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/stylesheets/framework/common.scss) that use non-design-system values should be avoided. Use classes with conforming values instead.

Avoid [Bootstrap's Utility Classes](https://getbootstrap.com/docs/4.3/utilities/).

NOTE:
While migrating [Bootstrap's Utility Classes](https://getbootstrap.com/docs/4.3/utilities/)
to the [GitLab UI](https://gitlab.com/gitlab-org/gitlab-ui/-/blob/main/doc/css.md#utilities)
utility classes, note both the classes for margin and padding differ. The size scale used at
GitLab differs from the scale used in the Bootstrap library. For a Bootstrap padding or margin
utility, you may need to double the size of the applied utility to achieve the same visual
result (such as `ml-1` becoming `gl-ml-2`).

### Where should you put new utility classes?

Because we are in the process of [migrating to Tailwind](#tailwind-css) the utility class you need may already be
available from Tailwind. The [IntelliSense for VS Code plugin](https://tailwindcss.com/docs/editor-setup#intelli-sense-for-vs-code) will tell you what utility classes are available. If the utility class you need is not available from Tailwind, you should continue to use the [utility classes defined in GitLab UI](https://gitlab.com/gitlab-org/gitlab-ui/-/blob/main/doc/css.md#utilities) which can be [seen on Unpkg](https://unpkg.com/browse/@gitlab/ui/src/scss/utilities.scss). If the utility class is still not available we need to enable a new core plugin in Tailwind. [Find the relevant core plugin](https://tailwindcss.com/docs/theme#configuration-reference) and open a MR to add the core plugin to the `corePlugins` array in [tailwind.defaults.js](https://gitlab.com/gitlab-org/gitlab-ui/-/blob/bad526b4662f38868cfc3d89157b22f5cc9a94c5/tailwind.defaults.js).

### When should you create component classes?

We recommend a "utility-first" approach.

1. Start with utility classes.
1. If composing utility classes into a component class removes code duplication and encapsulates a clear responsibility, do it.

This encourages an organic growth of component classes and prevents the creation of one-off non-reusable classes. Also, the kind of classes that emerge from "utility-first" tend to be design-centered (for example, `.button`, `.alert`, `.card`) rather than domain-centered (for example, `.security-report-widget`, `.commit-header-icon`).

Inspiration:

- <https://tailwindcss.com/docs/utility-first>
- <https://tailwindcss.com/docs/extracting-components>

### Utility mixins

We are currently in the process of [migrating to Tailwind](#tailwind-css). The migration removes utility mixins so please do not add any new usages of utility mixins. Instead use [pre-defined CSS keywords](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Values_and_Units#pre-defined_keyword_values) with SCSS variables.

```scss
// Bad
.my-class {
  @include gl-mt-3;
}

// Very bad
.my-class {
  @include gl-deprecated-mt-3;
}

// Bad
.my-class {
  margin-top: 0.5rem;
}

// Good
.my-class {
  margin-top: $gl-spacing-scale-3;
}
```

## Naming

Filenames should use `snake_case`.

CSS classes should use the `lowercase-hyphenated` format rather than
`snake_case` or `camelCase`.

```scss
// Bad
.class_name {
  color: #fff;
}

// Bad
.className {
  color: #fff;
}

// Good
.class-name {
  color: #fff;
}
```

Avoid making compound class names with SCSS `&` features. It makes
searching for usages harder, and provides limited benefit.

```scss
// Bad
.class {
  &-name {
    color: orange;
  }
}

// Good
.class-name {
  color: #fff;
}
```

Class names should be used instead of tag name selectors.
Using tag name selectors is discouraged because they can affect
unintended elements in the hierarchy.

```scss
// Bad
ul {
  color: #fff;
}

// Good
.class-name {
  color: #fff;
}

// Best
// prefer an existing utility class over adding existing styles
```

Class names are also preferable to IDs. Rules that use IDs
are not-reusable, as there can only be one affected element on
the page.

```scss
// Bad
#my-element {
  padding: 0;
}

// Good
.my-element {
  padding: 0;
}
```

## Nesting

Avoid unnecessary nesting. The extra specificity of a wrapper component
makes things harder to override.

```scss
// Bad
.component-container {
  .component-header {
    /* ... */
  }

  .component-body {
    /* ... */
  }
}

// Good
.component-container {
  /* ... */
}

.component-header {
  /* ... */
}

.component-body {
  /* ... */
}
```

## Selectors with a `js-` Prefix

Do not use any selector prefixed with `js-` for styling purposes. These
selectors are intended for use only with JavaScript to allow for removal or
renaming without breaking styling.

## Using `extend` at-rule

Usage of the `extend` at-rule is prohibited due to [memory leaks](https://gitlab.com/gitlab-org/gitlab/-/issues/323021) and [the rule doesn't work as it should](https://sass-lang.com/documentation/breaking-changes/extend-compound/).

## Linting

We use [stylelint](https://stylelint.io) to check for style guide conformity. It uses the
ruleset in `.stylelintrc` and rules from [our SCSS configuration](https://gitlab.com/gitlab-org/frontend/gitlab-stylelint-config). `.stylelintrc` is located in the home directory of the project.

To check if any warnings are produced by your changes, run `yarn lint:stylelint` in the GitLab directory. Stylelint also runs in GitLab CI/CD to
catch any warnings.

If the Rake task is throwing warnings you don't understand, SCSS Lint's
documentation includes [a full list of their rules](https://stylelint.io/user-guide/rules/).
