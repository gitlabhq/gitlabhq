# JavaScript style guide

We use [Airbnb's JavaScript Style Guide][airbnb-style-guide] and it's accompanying linter to manage most of our JavaScript style guidelines.

In addition to the style guidelines set by Airbnb, we also have a few specific rules listed below.

> **Tip:**
You can run eslint locally by running `yarn eslint`

## Arrays

<a name="avoid-foreach"></a><a name="1.1"></a>
- [1.1](#avoid-foreach) **Avoid ForEach when mutating data** Use `map`, `reduce` or `filter` instead of `forEach` when mutating data. This will minimize mutations in functions ([which is aligned with Airbnb's style guide][airbnb-minimize-mutations])

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

<a name="limit-params"></a><a name="2.1"></a>
- [2.1](#limit-params) **Limit number of parameters** If your function or method has more than 3 parameters, use an object as a parameter instead.

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

<a name="avoid-constructor-side-effects"></a><a name="3.1"></a>
- [3.1](#avoid-constructor-side-effects) **Avoid side effects in constructors** Avoid making some operations in the `constructor`, such as asynchronous calls, API requests and DOM manipulations. Prefer moving them into separate functions. This will make tests easier to write and code easier to maintain.

  ```javascript
  // bad
  class myClass {
    constructor(config) {
      this.config = config;
      axios.get(this.config.endpoint)
    }
  }

  // good
  class myClass {
    constructor(config) {
      this.config = config;
    }

    makeRequest() {
      axios.get(this.config.endpoint)
    }
  }
  const instance = new myClass();
  instance.makeRequest();

  ```

<a name="avoid-classes-to-handle-dom-events"></a><a name="3.2"></a>
- [3.2](#avoid-classes-to-handle-dom-events) **Avoid classes to handle DOM events** If the only purpose of the class is to bind a DOM event and handle the callback, prefer using a function.

```
// bad
class myClass {
  constructor(config) {
    this.config = config;
  }

  init() {
    document.addEventListener('click', () => {});
  }
}

// good

const myFunction = () => {
  document.addEventListener('click', () => {
    // handle callback here
  });
}
```

<a name="element-container"></a><a name="3.3"></a>
- [3.3](#element-container) **Pass element container to constructor** When your class manipulates the DOM, receive the element container as a parameter.
This is more maintainable and performant.

```
// bad
class a {
  constructor() {
    document.querySelector('.b');
  }
}

// good
class a {
  constructor(options) {
    options.container.querySelector('.b');
  }
}
```

## Type Casting & Coercion

<a name="use-parseint"></a><a name="4.1"></a>
- [4.1](#use-parseint) **Use ParseInt** Use `ParseInt` when converting a numeric string into a number.

```
// bad
Number('10')


// good
parseInt('10', 10);
```

## CSS Selectors

<a name="use-js-prefix"></a><a name="5.1"></a>
- [5.1](#use-js-prefix) **Use js prefix** If a CSS class is only being used in JavaScript as a reference to the element, prefix the class name with `js-`

```
// bad
<button class="add-user"></button>

// good
<button class="js-add-user"></button>
```

## Modules

<a name="use-absolute-paths"></a><a name="6.1"></a>
- [6.1](#use-absolute-paths) **Use absolute paths for nearby modules** Use absolute paths if the module you are importing is less than two levels up.

```
// bad
import GitLabStyleGuide from '~/guides/GitLabStyleGuide';

// good
import GitLabStyleGuide from '../GitLabStyleGuide';
```

<a name="use-relative-paths"></a><a name="6.2"></a>
- [6.2](#use-relative-paths) **Use relative paths for distant modules** If the module you are importing is two or more levels up, use a relative path instead of an absolute path.

```
// bad
import GitLabStyleGuide from '../../../guides/GitLabStyleGuide';

// good
import GitLabStyleGuide from '~/GitLabStyleGuide';
```

<a name="global-namespace"></a><a name="6.3"></a>
- [6.3](#global-namespace) **Do not add to global namespace**

<a name="domcontentloaded"></a><a name="6.4"></a>
- [6.4](#domcontentloaded) **Do not use DOMContentLoaded in non-page modules** Imported modules should act the same each time they are loaded. `DOMContentLoaded` events are only allowed on modules loaded in the `/pages/*` directory because those are loaded dynamically with webpack.

## Security

<a name="avoid-xss"></a><a name="7.1"></a>
- [7.1](#avoid-xss) **Avoid XSS** Do not use `innerHTML`, `append()` or `html()` to set content. It opens up too many vulnerabilities.

## ESLint

<a name="disable-eslint-file"></a><a name="8.1"></a>
- [8.1](#disable-eslint-file) **Disabling ESLint in new files** Do not disable ESLint when creating new files. Existing files may have existing rules disabled due to legacy compatibility reasons but they are in the process of being refactored.

<a name="disable-eslint-rule"></a><a name="8.2"></a>
- [8.2](#disable-eslint-rule) **Disabling ESLint rule** Do not disable specific ESLint rules. Due to technical debt, you may disable the following rules only if you are invoking/instantiating existing code modules

  - [no-new][no-new]
  - [class-method-use-this][class-method-use-this]

> Note: Disable these rules on a per line basis. This makes it easier to refactor in the future. E.g. use `eslint-disable-next-line` or `eslint-disable-line`

[airbnb-style-guide]: https://github.com/airbnb/javascript
[airbnb-minimize-mutations]: https://github.com/airbnb/javascript#testing--for-real
[no-new]: http://eslint.org/docs/rules/no-new
[class-method-use-this]: http://eslint.org/docs/rules/class-methods-use-this
