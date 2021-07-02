---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
disqus_identifier: 'https://docs.gitlab.com/ee/development/fe_guide/style_guide_scss.html'
---

# SCSS style guide

This style guide recommends best practices for SCSS to make styles easy to read,
easy to maintain, and performant for the end-user.

## Rules

Our CSS is a mixture of current and legacy approaches. That means sometimes it may be difficult to follow this guide to the letter; it means you are likely to run into exceptions, where following the guide is difficult to impossible without major effort. In those cases, you may work with your reviewers and maintainers to identify an approach that does not fit these rules. Please endeavor to limit these cases.

### Utility Classes

In order to reduce the generation of more CSS as our site grows, prefer the use of utility classes over adding new CSS. In complex cases, CSS can be addressed by adding component classes.

#### Where are utility classes defined?

Prefer the use of [utility classes defined in GitLab UI](https://gitlab.com/gitlab-org/gitlab-ui/-/blob/main/doc/css.md#utilities).
<!-- vale gitlab.Spelling = NO -->
An easy list of classes can also be [seen on Unpkg](https://unpkg.com/browse/@gitlab/ui/src/scss/utilities.scss).
<!-- vale gitlab.Spelling = YES -->

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

#### Where should I put new utility classes?

If a class you need has not been added to GitLab UI, you get to add it! Follow the naming patterns documented in the [utility files](https://gitlab.com/gitlab-org/gitlab-ui/-/tree/main/src/scss/utility-mixins) and refer to [GitLab UI's CSS documentation](https://gitlab.com/gitlab-org/gitlab-ui/-/blob/main/doc/contributing/adding_css.md#adding-utility-mixins) for more details, especially about adding responsive and stateful rules.

If it is not possible to wait for a GitLab UI update (generally one day), add the class to [`utilities.scss`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/stylesheets/utilities.scss) following the same naming conventions documented in GitLab UI. A follow—up issue to backport the class to GitLab UI and delete it from GitLab should be opened.

#### When should I create component classes?

We recommend a "utility-first" approach.

1. Start with utility classes.
1. If composing utility classes into a component class removes code duplication and encapsulates a clear responsibility, do it.

This encourages an organic growth of component classes and prevents the creation of one-off non-reusable classes. Also, the kind of classes that emerge from "utility-first" tend to be design-centered (e.g. `.button`, `.alert`, `.card`) rather than domain-centered (e.g. `.security-report-widget`, `.commit-header-icon`).

Inspiration:

- <https://tailwindcss.com/docs/utility-first>
- <https://tailwindcss.com/docs/extracting-components>

### Naming

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

### Selectors with a `js-` Prefix

Do not use any selector prefixed with `js-` for styling purposes. These
selectors are intended for use only with JavaScript to allow for removal or
renaming without breaking styling.

### Variables

Before adding a new variable for a color or a size, guarantee:

- There isn't an existing one.
- There isn't a similar one we can use instead.

## Linting

We use [stylelint](https://stylelint.io) to check for style guide conformity. It uses the
ruleset in `.stylelintrc` and rules from [our SCSS configuration](https://gitlab.com/gitlab-org/frontend/gitlab-stylelint-config). `.stylelintrc` is located in the home directory of the project.

To check if any warnings are produced by your changes, run `yarn lint:stylelint` in the GitLab directory. Stylelint also runs in GitLab CI/CD to
catch any warnings.

If the Rake task is throwing warnings you don't understand, SCSS Lint's
documentation includes [a full list of their rules](https://stylelint.io/user-guide/rules/list/).

### Fixing issues

If you want to automate changing a large portion of the codebase to conform to
the SCSS style guide, you can use [CSSComb](https://github.com/csscomb/csscomb.js). First install
[Node](https://github.com/nodejs/node) and [npm](https://www.npmjs.com/), then run `npm install csscomb -g` to install
CSSComb globally (system-wide). Run it in the GitLab directory with
`csscomb app/assets/stylesheets` to automatically fix issues with CSS/SCSS.

Note that this doesn't fix every problem, but it should fix a majority.
