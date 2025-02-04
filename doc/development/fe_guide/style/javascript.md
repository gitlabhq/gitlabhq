---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: JavaScript style guide
---

We use [the Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript) and its accompanying
linter to manage most of our JavaScript style guidelines.

In addition to the style guidelines set by Airbnb, we also have a few specific rules
listed below.

NOTE:
You can run ESLint locally by running `yarn run lint:eslint:all` or `yarn run lint:eslint $PATH_TO_FILE`.

## Avoid `forEach`

Avoid `forEach` when mutating data. Use `map`, `reduce` or `filter` instead of `forEach`
when mutating data. This minimizes mutations in functions,
which aligns with [the Airbnb style guide](https://github.com/airbnb/javascript#testing--for-real).

```javascript
// bad
users.forEach((user, index) => {
  user.id = index;
});

// good
const usersWithId = users.map((user, index) => {
  return Object.assign({}, user, { id: index });
});
```

## Limit number of parameters

If your function or method has more than 3 parameters, use an object as a parameter
instead.

```javascript
// bad
function a(p1, p2, p3, p4) {
  // ...
};

// good
function a({ p1, p2, p3, p4 }) {
  // ...
};
```

## Avoid classes to handle DOM events

If the only purpose of the class is to bind a DOM event and handle the callback, prefer
using a function.

```javascript
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

## Pass element container to constructor

When your class manipulates the DOM, receive the element container as a parameter.
This is more maintainable and performant.

```javascript
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

## Converting Strings to Integers

When converting strings to integers, `Number` is semantic and can be more readable. Both are allowable, but `Number` has a slight maintainability advantage.

**WARNING:** `parseInt` **must** include the [radix argument](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/parseInt).

```javascript
// bad (missing radix argument)
parseInt('10');

// good
parseInt("106", 10);

// good
Number("106");
```

```javascript
// bad (missing radix argument)
things.map(parseInt);

// good
things.map(Number);
```

NOTE:
If the String could represent a non-integer (a number that includes a decimal), **do not** use `parseInt`. Consider `Number` or `parseFloat` instead.

## CSS Selectors - Use `js-` prefix

If a CSS class is only being used in JavaScript as a reference to the element, prefix
the class name with `js-`.

```html
// bad
<button class="add-user"></button>

// good
<button class="js-add-user"></button>
```

## ES Module Syntax

For most JavaScript files, use ES module syntax to import or export from modules.
Prefer named exports, as they improve name consistency.

```javascript
// bad (with exceptions, see below)
export default SomeClass;
import SomeClass from 'file';

// good
export { SomeClass };
import { SomeClass } from 'file';
```

Using default exports is acceptable in a few particular circumstances:

- Vue Single File Components (SFCs)
- Vuex mutation files

For more information, see [RFC 20](https://gitlab.com/gitlab-org/frontend/rfcs/-/issues/20).

## CommonJS Module Syntax

Our Node configuration requires CommonJS module syntax. Prefer named exports.

```javascript
// bad
module.exports = SomeClass;
const SomeClass = require('./some_class');

// good
module.exports = { SomeClass };
const { SomeClass } = require('./some_class');
```

## Absolute vs relative paths for modules

Use relative paths if the module you are importing is less than two levels up.

```javascript
// bad
import GitLabStyleGuide from '~/guides/GitLabStyleGuide';

// good
import GitLabStyleGuide from '../GitLabStyleGuide';
```

If the module you are importing is two or more levels up, use an absolute path instead:

```javascript
// bad
import GitLabStyleGuide from '../../../guides/GitLabStyleGuide';

// good
import GitLabStyleGuide from '~/GitLabStyleGuide';
```

Additionally, **do not add to global namespace**.

## Do not use `DOMContentLoaded` in non-page modules

Imported modules should act the same each time they are loaded. `DOMContentLoaded`
events are only allowed on modules loaded in the `/pages/*` directory because those
are loaded dynamically with webpack.

## Avoid XSS

Do not use `innerHTML`, `append()` or `html()` to set content. It opens up too many
vulnerabilities.

## ESLint

ESLint behavior can be found in our [tooling guide](../tooling.md).

## IIFEs

Avoid using IIFEs (Immediately-Invoked Function Expressions). Although
we have a lot of examples of files which wrap their contents in IIFEs,
this is no longer necessary after the transition from Sprockets to webpack.
Do not use them anymore and feel free to remove them when refactoring legacy code.

## Global namespace

Avoid adding to the global namespace.

```javascript
// bad
window.MyClass = class { /* ... */ };

// good
export default class MyClass { /* ... */ }
```

## Side effects

### Top-level side effects

Top-level side effects are forbidden in any script which contains `export`:

```javascript
// bad
export default class MyClass { /* ... */ }

document.addEventListener("DOMContentLoaded", function(event) {
  new MyClass();
}
```

### Avoid side effects in constructors

Avoid making asynchronous calls, API requests or DOM manipulations in the `constructor`.
Move them into separate functions instead. This makes tests easier to write and
avoids violating the [Single Responsibility Principle](https://en.wikipedia.org/wiki/Single_responsibility_principle).

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

## Pure Functions and Data Mutation

Strive to write many small pure functions and minimize where mutations occur

  ```javascript
  // bad
  const values = {foo: 1};

  function impureFunction(items) {
    const bar = 1;

    items.foo = items.a * bar + 2;

    return items.a;
  }

  const c = impureFunction(values);

  // good
  var values = {foo: 1};

  function pureFunction (foo) {
    var bar = 1;

    foo = foo * bar + 2;

    return foo;
  }

  var c = pureFunction(values.foo);
  ```

## Export constants as primitives

Prefer exporting constant primitives with a common namespace over exporting objects. This allows for better compile-time reference checks and helps to avoid accidental `undefined`s at runtime. In addition, it helps in reducing bundle sizes.

Only export the constants as a collection (array, or object) when there is a need to iterate over them, for instance, for a prop validator.

  ```javascript
  // bad
  export const VARIANT = {
    WARNING: 'warning',
    ERROR: 'error',
  };

  // good
  export const VARIANT_WARNING = 'warning';
  export const VARIANT_ERROR = 'error';

  // good, if the constants need to be iterated over
  export const VARIANTS = [VARIANT_WARNING, VARIANT_ERROR];
  ```

## Error handling

For internal server errors when the server returns `500`, you should return a
generic error message.

When the backend returns errors, the errors should be
suitable to display back to the user.

If for some reason, it is difficult to do so, as a last resort, you can
select particular error messages with prefixing:

1. Ensure that the backend prefixes the error messages to be displayed with:

   ```ruby
   Gitlab::Utils::ErrorMessage.to_user_facing('Example user-facing error-message')
   ```

1. Use the error message utility function contained in `app/assets/javascripts/lib/utils/error_message.js`.

This utility accepts two parameters: the error object received from the server response and a
default error message. The utility examines the message in the error object for a prefix that
indicates whether the message is meant to be user-facing or not. If the message is intended
to be user-facing, the utility returns it as is. Otherwise, it returns the default error
message passed as a parameter.

```javascript
import { parseErrorMessage } from '~/lib/utils/error_message';

onError(error) {
  const errorMessage = parseErrorMessage(error, genericErrorText);
}
```

Note that this prefixing must not be used for API responses. Instead follow the
[REST API](../../../api/rest/troubleshooting.md#status-code-400),
or [GraphQL guides](../../api_graphql_styleguide.md#error-handling) on how to consume error objects.
