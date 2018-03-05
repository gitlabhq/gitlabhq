# SCSS style guide

We use [SCSS Lint][scss-lint] to check our styles.

> **Tip:**
You can lint your SCSS locally by running `rake scss_lint`.

> **Tip:**
You can autofix your lint errors locally by using [CSSComb][cssComb]. After installing CSSComb, run `csscomb app/assets/stylesheets`. This won't fix all lint errors but it should fix most of them.

## Selectors

<a name="js-class"></a><a name="1.1"></a>
- [1.1](#js-class) **Avoid styling js- classes** CSS class names with a `js-` prefix are not used for styling. They are purely used for querying the DOM.


<a name="id-selectors"></a><a name="1.2"></a>
- [1.2](#id-selectors) **Avoid ID selectors**

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

<a name="new-variables"></a><a name="2.1"></a>
- [2.1](#new-variables) **Avoid creating new variables** Check to see if there is a similar variable before adding a new variable.

## SCSS Lint

<a name="disable-scss-lint"></a><a name="3.1"></a>
- [3.1](#disable-scss-lint) **Disabling SCSS Lint rule** Avoid disable specific SCSS Lint rules. If you absolutely have to, make sure you comment a reason above the `disable` rule.

```
// This lint rule is disabled because the class name comes from a gem.
// scss-lint:disable SelectorFormat
.ui_indigo {
  background-color: #333;
}
// scss-lint:enable SelectorFormat
```

[scss-lint]: https://github.com/brigade/scss-lint
[cssComb]: http://csscomb.com/
