# SCSS style guide

We use [SCSS Lint][scss-lint] to check our styles.

> **Tip:**
You can lint your SCSS locally by running `rake scss_lint`.

> **Tip:**
You can autofix your lint errors locally by using [CSSComb][cssComb]. After installing CSSComb, run `csscomb app/assets/stylesheets`. This won't fix all lint errors but it should fix most of them.

## Selectors

- 1.1 **Avoid styling js- classes** CSS class names with a `js-` prefix are not used for styling. They are purely used for querying the DOM.


- 1.2 **Avoid ID selectors**

```
// Bad
#my-element {
  padding: 0;
}

// Good
.my-element {
  padding: 0;
}
```

## Variables

- 2.1 **Avoid creating new variables** Check to see if there is a similar variable before adding a new variable.

## SCSS Lint

- 3.1 **Disabling SCSS Lint rule** Avoid disable specific SCSS Lint rules. If you absolutely have to, make sure you comment a reason above the `disable` rule.

```
// This lint rule is disabled because the class name comes from a gem.
// scss-lint:disable SelectorFormat
.ui_indigo {
  background-color: #333;
}
// scss-lint:enable SelectorFormat
```

[scss-lint]: https://github.com/brigade/scss-lint
