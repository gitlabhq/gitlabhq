---
disqus_identifier: 'https://docs.gitlab.com/ee/development/fe_guide/style_guide_scss.html'
---

# SCSS style guide

This style guide recommends best practices for SCSS to make styles easy to read,
easy to maintain, and performant for the end-user.

## Rules

### Utility Classes

As part of the effort for [cleaning up our CSS and moving our components into gitlab-ui](https://gitlab.com/groups/gitlab-org/-/epics/950)
led by the [GitLab UI WG](https://gitlab.com/gitlab-com/www-gitlab-com/merge_requests/20623) we prefer the use of utility classes over adding new CSS. However, complex CSS can be addressed by adding component classes.

#### Where are utility classes defined?

- [Bootstrap's Utility Classes](https://getbootstrap.com/docs/4.3/utilities/)
- [`common.scss`](https://gitlab.com/gitlab-org/gitlab/blob/master/app/assets/stylesheets/framework/common.scss) (old)
- [`utilities.scss`](https://gitlab.com/gitlab-org/gitlab/blob/master/app/assets/stylesheets/utilities.scss) (new)

#### Where should I put new utility classes?

New utility classes should be added to [`utilities.scss`](https://gitlab.com/gitlab-org/gitlab/blob/master/app/assets/stylesheets/utilities.scss). Existing classes include:

| Name | Pattern | Example |
|------|---------|---------|
| Background color | `.bg-{variant}-{shade}` | `.bg-warning-400` |
| Text color | `.text-{variant}-{shade}` | `.text-success-500` |
| Font size | `.text-{size}` | `.text-2` |

- `{variant}` is one of 'primary', 'secondary', 'success', 'warning', 'error'
- `{shade}` is one of the shades listed on [colors](https://design.gitlab.com/product-foundations/colors/)
- `{size}` is a number from 1-6 from our [Type scale](https://design.gitlab.com/product-foundations/typography/)

#### When should I create component classes?

We recommend a "utility-first" approach.

1. Start with utility classes.
1. If composing utility classes into a component class removes code duplication and encapsulates a clear responsibility, do it.

This encourages an organic growth of component classes and prevents the creation of one-off unreusable classes. Also, the kind of classes that emerge from "utility-first" tend to be design-centered (e.g. `.button`, `.alert`, `.card`) rather than domain-centered (e.g. `.security-report-widget`, `.commit-header-icon`).

Examples of component classes that were created using "utility-first" include:

- [`.circle-icon-container`](https://gitlab.com/gitlab-org/gitlab/blob/579fa8b8ec7eb38d40c96521f517c9dab8c3b97a/app/assets/stylesheets/framework/icons.scss#L85)
- [`.d-flex-center`](https://gitlab.com/gitlab-org/gitlab/blob/900083d89cd6af391d26ab7922b3f64fa2839bef/app/assets/stylesheets/framework/common.scss#L425)

Inspiration:

- <https://tailwindcss.com/docs/utility-first/>
- <https://tailwindcss.com/docs/extracting-components/>

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
scss_lint` in the GitLab directory. SCSS Lint will also run in GitLab CI to
catch any warnings.

If the Rake task is throwing warnings you don't understand, SCSS Lint's
documentation includes [a full list of their linters](https://github.com/sds/scss-lint/blob/master/lib/scss_lint/linter/README.md).

### Fixing issues

If you want to automate changing a large portion of the codebase to conform to
the SCSS style guide, you can use [CSSComb][csscomb]. First install
[Node][node] and [NPM][npm], then run `npm install csscomb -g` to install
CSSComb globally (system-wide). Run it in the GitLab directory with
`csscomb app/assets/stylesheets` to automatically fix issues with CSS/SCSS.

Note that this won't fix every problem, but it should fix a majority.

### Ignoring issues

If you want a line or set of lines to be ignored by the linter, you can use
`// scss-lint:disable RuleName` ([more info](https://github.com/sds/scss-lint#disabling-linters-via-source)):

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

[csscomb]: https://github.com/csscomb/csscomb.js
[node]: https://github.com/nodejs/node
[npm]: https://www.npmjs.com/
