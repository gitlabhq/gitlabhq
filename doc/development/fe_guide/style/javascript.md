# JavaScript style guide

We use [Airbnb's JavaScript Style Guide](https://github.com/airbnb/javascript) to manage most of our JavaScript styling guidelines. We also use their eslint present to make sure we follow those guidelines.

In addition to the style guidelines set by Airbnb, we also have a few specific rules listed below.

## Arrays

- 1.1 **Avoid ForEach when mutating data** Use `map`, `reduce` or `filter` instead of `forEach` when mutating data. This will minimize mutations in functions ([which is aligned with Airbnb's style guide](https://github.com/airbnb/javascript#testing--for-real))

```
// bad
users.forEach((user, index) => {
  user.id = index;
});

// good
const usersWithId = users.map((user, index) => {
  return Object.assign({}, user, { id: index });
});
```

## Functions

- 2.1 **Limit number of parameters** If your function or method has more than 3 parameters, use an object as a parameter instead.

```
// bad
function a(p1, p2, p3) {
  // ...
};

// good
function a(p) {
  // ...
};
```

## Classes & constructors

- 3.1 **Avoid side effects in constructors**

```
// bad
class myClass {
  constructor(config) {
    this.config = config;
    document.addEventListener('click', () => {});
  }
}

// good
class myClass {
  constructor(config) {
    this.config = config;
  }

  init() {
    document.addEventListener('click', () => {});
  }
}
```

## Type Casting & Coercion

- 4.1 **Use ParseInt** Use `ParseInt` when converting a numeric string into a number.

```
// bad
Number('10')


// good
parseInt('10', 10);
```

## CSS

- 5.1 **Use js prefix** If a CSS class is only being used in JavaScript as a reference to the element, prefix the class name with `js-`

```
// bad
<button class="add-user"></button>

// good
<button class="js-add-user"></button>
```

## Modules

- 6.1 **Use absolute paths** Use absolute paths if the module you are importing is less than two levels up.

```
// bad
import GitLabStyleGuide from '~/guides/GitLabStyleGuide';

// good
import GitLabStyleGuide from '../GitLabStyleGuide';
```

- 6.2 **Use relative paths** If the module you are importing is two or more levels up, use a relative path instead of an absolute path.

```
// bad
import GitLabStyleGuide from '../../../guides/GitLabStyleGuide';

// good
import GitLabStyleGuide from '~/GitLabStyleGuide';
```

- 6.3 **Do not add to global namepsace**

- 6.4 **Do not use DOMContentLoaded in non-page modules** Imported modules should act the same each time they are loaded. `DOMContentLoaded` events are only allowed on modules loaded in the `/pages/*` directory because those are loaded dynamically with webpack.

## ESLint

- 7.1 **Disabling ESLint in new files** Do not disable ESLint when creating new files. Existing files may have existing rules disabled due to legacy compataiblity reasons but they are in the process of being refactored.

- 7.2 **Disabling ESLint rule** Do not disable specific ESLint rules. Due to technical debt, you may disable the following rules only if you are invoking/instantiating existing code modules

  - [no-new](http://eslint.org/docs/rules/no-new)
  - [class-method-use-this](http://eslint.org/docs/rules/class-methods-use-this)

> Note: Disable these rules on a per line basis. This makes it easier to refactor in the future. E.g. use `eslint-disable-next-line` or `eslint-disable-line`
