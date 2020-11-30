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

Our CSS is a mixture of current and legacy approaches. That means sometimes it may be difficult to follow this guide to the letter; it means you will definitely run into exceptions, where following the guide is difficult to impossible without outsized effort. In those cases, you may work with your reviewers and maintainers to identify an approach that does not fit these rules. Please endeavor to limit these cases.

### Utility Classes

In order to reduce the generation of more CSS as our site grows, prefer the use of utility classes over adding new CSS. In complex cases, CSS can be addressed by adding component classes.

#### Where are utility classes defined?

Prefer the use of [utility classes defined in GitLab UI](https://gitlab.com/gitlab-org/gitlab-ui/-/blob/master/doc/css.md#utilities). An easy list of classes can also be [seen on Unpkg](https://unpkg.com/browse/@gitlab/ui/src/scss/utilities.scss).

Classes in [`utilities.scss`](https://gitlab.com/gitlab-org/gitlab/blob/master/app/assets/stylesheets/utilities.scss) and [`common.scss`](https://gitlab.com/gitlab-org/gitlab/blob/master/app/assets/stylesheets/framework/common.scss) are being deprecated. Classes in [`common.scss`](https://gitlab.com/gitlab-org/gitlab/blob/master/app/assets/stylesheets/framework/common.scss) that use non-design system values should be avoided in favor of conformant values.

Avoid [Bootstrap's Utility Classes](https://getbootstrap.com/docs/4.3/utilities/).

NOTE: **Note:**
While migrating [Bootstrap's Utility Classes](https://getbootstrap.com/docs/4.3/utilities/)
to the [GitLab UI](https://gitlab.com/gitlab-org/gitlab-ui/-/blob/master/doc/css.md#utilities)
utility classes, note both the classes for margin and padding differ. The size scale used at
GitLab differs from the scale used in the Bootstrap library. For a Bootstrap padding or margin
utility, you may need to double the size of the applied utility to achieve the same visual
result (such as `ml-1` becoming `gl-ml-2`).

#### Where should I put new utility classes?

If a class you need has not been added to GitLab UI, you get to add it! Follow the naming patterns documented in the [utility files](https://gitlab.com/gitlab-org/gitlab-ui/-/tree/master/src/scss/utility-mixins) and refer to [GitLab UI's CSS documentation](https://gitlab.com/gitlab-org/gitlab-ui/-/blob/master/doc/contributing/adding_css.md#adding-utility-mixins) for more details, especially about adding responsive and stateful rules.

If it is not possible to wait for a GitLab UI update (generally one day), add the class to [`utilities.scss`](https://gitlab.com/gitlab-org/gitlab/blob/master/app/assets/stylesheets/utilities.scss) following the same naming conventions documented in GitLab UI. A follow—up issue to backport the class to GitLab UI and delete it from GitLab should be opened.

#### When should I create component classes?

We recommend a "utility-first" approach.

1. Start with utility classes.
1. If composing utility classes into a component class removes code duplication and encapsulates a clear responsibility, do it.

This encourages an organic growth of component classes and prevents the creation of one-off unreusable classes. Also, the kind of classes that emerge from "utility-first" tend to be design-centered (e.g. `.button`, `.alert`, `.card`) rather than domain-centered (e.g. `.security-report-widget`, `.commit-header-icon`).

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
Using tag name selectors are discouraged in CSS because
they can affect unintended elements in the hierarchy.
Also, since they are not meaningful names, they do not
add meaning to the code.

```scss
// Bad
ul {
  color: #fff;
}

// Good
.class-name {
  color: #fff;
}
```

### Formatting

You should always use a space before a brace, braces should be on the same
line, each property should each get its own line, and there should be a space
between the property and its value.

```scss
// Bad
.container-item {
  width: 100px; height: 100px;
  margin-top: 0;
}

// Bad
.container-item
{
  width: 100px;
  height: 100px;
  margin-top: 0;
}

// Bad
.container-item{
  width:100px;
  height:100px;
  margin-top:0;
}

// Good
.container-item {
  width: 100px;
  height: 100px;
  margin-top: 0;
}
```

Note that there is an exception for single-line rulesets, although these are
not typically recommended.

```scss
p { margin: 0; padding: 0; }
```

### Colors

HEX (hexadecimal) colors should use shorthand where possible, and should use
lower case letters to differentiate between letters and numbers, e.g. `#E3E3E3`
vs. `#e3e3e3`.

```scss
// Bad
p {
  color: #ffffff;
}

// Bad
p {
  color: #FFFFFF;
}

// Good
p {
  color: #fff;
}
```

### Indentation

Indentation should always use two spaces for each indentation level.

```scss
// Bad, four spaces
p {
    color: #f00;
}

// Good
p {
  color: #f00;
}
```

### Semicolons

Always include semicolons after every property. When the stylesheets are
minified, the semicolons will be removed automatically.

```scss
// Bad
.container-item {
  width: 100px;
  height: 100px
}

// Good
.container-item {
  width: 100px;
  height: 100px;
}
```

### Shorthand

The shorthand form should be used for properties that support it.

```scss
// Bad
margin: 10px 15px 10px 15px;
padding: 10px 10px 10px 10px;

// Good
margin: 10px 15px;
padding: 10px;
```

### Zero Units

Omit length units on zero values, they're unnecessary and not including them
is slightly more performant.

```scss
// Bad
.item-with-padding {
  padding: 0px;
}

// Good
.item-with-padding {
  padding: 0;
}
```

### Selectors with a `js-` Prefix

Do not use any selector prefixed with `js-` for styling purposes. These
selectors are intended for use only with JavaScript to allow for removal or
renaming without breaking styling.

### IDs

Don't use ID selectors in CSS.

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

### Variables

Before adding a new variable for a color or a size, guarantee:

- There isn't already one
- There isn't a similar one we can use instead.

## Linting

We use [SCSS Lint](https://github.com/sds/scss-lint) to check for style guide conformity. It uses the
ruleset in `.scss-lint.yml`, which is located in the home directory of the
project.

To check if any warnings will be produced by your changes, you can run `rake
scss_lint` in the GitLab directory. SCSS Lint will also run in GitLab CI/CD to
catch any warnings.

If the Rake task is throwing warnings you don't understand, SCSS Lint's
documentation includes [a full list of their linters](https://github.com/sds/scss-lint/blob/master/lib/scss_lint/linter/README.md).

### Fixing issues

If you want to automate changing a large portion of the codebase to conform to
the SCSS style guide, you can use [CSSComb](https://github.com/csscomb/csscomb.js). First install
[Node](https://github.com/nodejs/node) and [NPM](https://www.npmjs.com/), then run `npm install csscomb -g` to install
CSSComb globally (system-wide). Run it in the GitLab directory with
`csscomb app/assets/stylesheets` to automatically fix issues with CSS/SCSS.

Note that this won't fix every problem, but it should fix a majority.

### Ignoring issues

If you want a line or set of lines to be ignored by the linter, you can use
`// scss-lint:disable RuleName` ([more information](https://github.com/sds/scss-lint#disabling-linters-via-source)):

```scss
// This lint rule is disabled because it is supported only in Chrome/Safari
// scss-lint:disable PropertySpelling
body {
  text-decoration-skip: ink;
}
// scss-lint:enable PropertySpelling
```

Make sure a comment is added on the line above the `disable` rule, otherwise the
linter will throw a warning. `DisableLinterReason` is enabled to make sure the
style guide isn't being ignored, and to communicate to others why the style
guide is ignored in this instance.
