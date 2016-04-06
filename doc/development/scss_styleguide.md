# SCSS styleguide

This style guide recommends best practices for SCSS to make styles easy to read,
easy to maintain, and performant for the end-user.

## Rules

### Naming

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

## Linting

We use [SCSS Lint][scss-lint] to check for style guide conformity. It uses the 
ruleset in `.scss-lint.yml`, which is located in the home directory of the 
project.

To check if any warnings will be produced by your changes, you can run `rake 
scss_lint` in the GitLab directory. SCSS Lint will also run in GitLab CI to 
catch any warnings.

If the Rake task is throwing warnings you don't understand, SCSS Lint's 
documentation includes [a full list of their linters][scss-lint-documentation].

### Fixing issues

If you want to automate changing a large portion of the codebase to conform to 
the SCSS style guide, you can use [CSSComb][csscomb]. First install
[Node][node] and [NPM][npm], then run `npm install csscomb -g` to install 
CSSComb globally (system-wide). Run it in the GitLab directory with 
`csscomb app/assets/stylesheets` to automatically fix issues with CSS/SCSS.

Note that this won't fix every problem, but it should fix a majority.

### Ignoring issues

If you want a line or set of lines to be ignored by the linter, you can use 
`// scss-lint:disable RuleName` ([more info][disabling-linters]):

```scss
// This lint rule is disabled because the class name comes from a gem.
// scss-lint:disable SelectorFormat
.ui_charcoal {
  background-color: #333;
}
// scss-lint:enable SelectorFormat
```

Make sure a comment is added on the line above the `disable` rule, otherwise the
linter will throw a warning. `DisableLinterReason` is enabled to make sure the 
style guide isn't being ignored, and to communicate to others why the style 
guide is ignored in this instance.

[csscomb]: https://github.com/csscomb/csscomb.js
[node]: https://github.com/nodejs/node
[npm]: https://www.npmjs.com/
[scss-lint]: https://github.com/brigade/scss-lint
[scss-lint-documentation]: https://github.com/brigade/scss-lint/blob/master/lib/scss_lint/linter/README.md
[disabling-linters]: https://github.com/brigade/scss-lint#disabling-linters-via-source
