# Style guides and linting
See the relevant style guides for our guidelines and for information on linting:

## JavaScript
We defer to [Airbnb][airbnb-js-style-guide] on most style-related
conventions and enforce them with eslint.

See [our current .eslintrc][eslintrc] for specific rules and patterns.

### Common

#### ESlint

1. **Never** disable eslint rules unless you have a good reason.
You may see a lot of legacy files with `/* eslint-disable some-rule, some-other-rule */`
at the top, but legacy files are a special case.  Any time you develop a new feature or
refactor an existing one, you should abide by the eslint rules.

1. **Never Ever EVER** disable eslint globally for a file
  ```javascript
    // bad
    /* eslint-disable */

    // better
    /* eslint-disable some-rule, some-other-rule */

    // best
    // nothing :)
  ```

1. If you do need to disable a rule for a single violation, try to do it as locally as possible
  ```javascript
    // bad
    /* eslint-disable no-new */

    import Foo from 'foo';

    new Foo();

    // better
    import Foo from 'foo';

    // eslint-disable-next-line no-new
    new Foo();
  ```
1. There are few rules that we need to disable due to technical debt. Which are:
  1. [no-new][eslint-new]
  1. [class-methods-use-this][eslint-this]

1. When they are needed _always_ place ESlint directive comment blocks on the first line of a script,
followed by any global declarations, then a blank newline prior to any imports or code.
  ```javascript
    // bad
    /* global Foo */
    /* eslint-disable no-new */
    import Bar from './bar';

    // good
    /* eslint-disable no-new */
    /* global Foo */

    import Bar from './bar';
  ```

1. **Never** disable the `no-undef` rule. Declare globals with `/* global Foo */` instead.

1. When declaring multiple globals, always use one `/* global [name] */` line per variable.
  ```javascript
    // bad
    /* globals Flash, Cookies, jQuery */

    // good
    /* global Flash */
    /* global Cookies */
    /* global jQuery */
  ```

1. Use up to 3 parameters for a function or class. If you need more accept an Object instead.
  ```javascript
    // bad
    fn(p1, p2, p3, p4) {}

    // good
    fn(options) {}
  ```

#### Modules, Imports, and Exports
1. Use ES module syntax to import modules
    ```javascript
      // bad
      const SomeClass = require('some_class');

      // good
      import SomeClass from 'some_class';

      // bad
      module.exports = SomeClass;

      // good
      export default SomeClass;
    ```

    Import statements are following usual naming guidelines, for example object literals use camel case:

    ```javascript
      // some_object file
      export default {
        key: 'value',
      };

      // bad
      import ObjectLiteral from 'some_object';

      // good
      import objectLiteral from 'some_object';
    ```

1. Relative paths: when importing a module in the same directory, a child
directory, or an immediate parent directory prefer relative paths.  When
importing a module which is two or more levels up, prefer either `~/` or `ee/`.

    In **app/assets/javascripts/my-feature/subdir**:

    ```javascript
    // bad
    import Foo from '~/my-feature/foo';
    import Bar from '~/my-feature/subdir/bar';
    import Bin from '~/my-feature/subdir/lib/bin';

    // good
    import Foo from '../foo';
    import Bar from './bar';
    import Bin from './lib/bin';
    ```

    In **spec/javascripts**:

    ```javascript
    // bad
    import Foo from '../../app/assets/javascripts/my-feature/foo';

    // good
    import Foo from '~/my-feature/foo';
    ```

    When referencing an **EE component**:

    ```javascript
    // bad
    import Foo from '../../../../../ee/app/assets/javascripts/my-feature/ee-foo';

    // good
    import Foo from 'ee/my-feature/foo';
    ```

1. Avoid using IIFE. Although we have a lot of examples of files which wrap their
contents in IIFEs (immediately-invoked function expressions),
this is no longer necessary after the transition from Sprockets to webpack.
Do not use them anymore and feel free to remove them when refactoring legacy code.

1. Avoid adding to the global namespace.
    ```javascript
      // bad
      window.MyClass = class { /* ... */ };

      // good
      export default class MyClass { /* ... */ }
    ```

1. Side effects are forbidden in any script which contains exports
    ```javascript
      // bad
      export default class MyClass { /* ... */ }

      document.addEventListener("DOMContentLoaded", function(event) {
        new MyClass();
      }
    ```

#### Data Mutation and Pure functions
1. Strive to write many small pure functions, and minimize where mutations occur.
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

1. Avoid constructors with side-effects.
Although we aim for code without side-effects we need some side-effects for our code to run.

If the class won't do anything if we only instantiate it, it's ok to add side effects into the constructor (_Note:_ The following is just an example. If the only purpose of the class is to add an event listener and handle the callback a function will be more suitable.)

```javascript
// Bad
export class Foo {
  constructor() {
    this.init();
  }
  init() {
    document.addEventListener('click', this.handleCallback)
  },
  handleCallback() {

  }
}

// Good
export class Foo {
  constructor() {
    document.addEventListener()
  }
  handleCallback() {
  }
}
```

On the other hand, if a class only needs to extend a third party/add event listeners in some specific cases, they should be initialized oustside of the constructor.

1. Prefer `.map`, `.reduce` or `.filter` over `.forEach`
A forEach will most likely cause side effects, it will be mutating the array being iterated. Prefer using `.map`,
`.reduce` or `.filter`
  ```javascript
    const users = [ { name: 'Foo' }, { name: 'Bar' } ];

    // bad
    users.forEach((user, index) => {
      user.id = index;
    });

    // good
    const usersWithId = users.map((user, index) => {
      return Object.assign({}, user, { id: index });
    });
  ```

#### Parse Strings into Numbers
1. `parseInt()` is preferable over `Number()` or `+`
  ```javascript
    // bad
    +'10' // 10

    // good
    Number('10') // 10

    // better
    parseInt('10', 10);
  ```

#### CSS classes used for JavaScript
1. If the class is being used in Javascript it needs to be prepend with `js-`
  ```html
    // bad
    <button class="add-user">
      Add User
    </button>

    // good
    <button class="js-add-user">
      Add User
    </button>
  ```

### Vue.js

#### `eslint-vue-plugin`
We default to [eslint-vue-plugin][eslint-plugin-vue], with the `plugin:vue/recommended`.
Please check this [rules][eslint-plugin-vue-rules] for more documentation.

#### Basic Rules
1. The service has it's own file
1. The store has it's own file
1. Use a function in the bundle file to instantiate the Vue component:
  ```javascript
    // bad
    class {
      init() {
        new Component({})
      }
    }

    // good
    document.addEventListener('DOMContentLoaded', () => new Vue({
      el: '#element',
      components: {
        componentName
      },
      render: createElement => createElement('component-name'),
    }));
  ```

1. Don not use a singleton for the service or the store
  ```javascript
    // bad
    class Store {
      constructor() {
        if (!this.prototype.singleton) {
          // do something
        }
      }
    }

    // good
    class Store {
      constructor() {
        // do something
      }
    }
  ```

#### Naming
1. **Extensions**: Use `.vue` extension for Vue components.
1. **Reference Naming**: Use PascalCase for their instances:
  ```javascript
    // bad
    import cardBoard from 'cardBoard.vue'

    components: {
      cardBoard,
    };

    // good
    import CardBoard from 'cardBoard.vue'

    components: {
      CardBoard,
    };
  ```

1. **Props Naming:**  Avoid using DOM component prop names.
1. **Props Naming:** Use kebab-case instead of camelCase to provide props in templates.
  ```javascript
    // bad
    <component class="btn">

    // good
    <component css-class="btn">

    // bad
    <component myProp="prop" />

    // good
    <component my-prop="prop" />
  ```

#### Alignment
1. Follow these alignment styles for the template method:
  1. With more than one attribute, all attributes should be on a new line:
      ```javascript
        // bad
        <component v-if="bar"
            param="baz" />

        <button class="btn">Click me</button>

        // good
        <component
          v-if="bar"
          param="baz"
        />

        <button class="btn">
          Click me
        </button>
      ```
  1. The tag can be inline if there is only one attribute:
      ```javascript
        // good
          <component bar="bar" />

        // good
          <component
            bar="bar"
            />

        // bad
         <component
            bar="bar" />
      ```

#### Quotes
1. Always use double quotes `"` inside templates and single quotes `'` for all other JS.
  ```javascript
    // bad
    template: `
      <button :class='style'>Button</button>
    `

    // good
    template: `
      <button :class="style">Button</button>
    `
  ```

#### Props
1. Props should be declared as an object
  ```javascript
    // bad
    props: ['foo']

    // good
    props: {
      foo: {
        type: String,
        required: false,
        default: 'bar'
      }
    }
  ```

1. Required key should always be provided when declaring a prop
  ```javascript
    // bad
    props: {
      foo: {
        type: String,
      }
    }

    // good
    props: {
      foo: {
        type: String,
        required: false,
        default: 'bar'
      }
    }
  ```

1. Default key should be provided if the prop is not required.
_Note:_ There are some scenarios where we need to check for the existence of the property.
On those a default key should not be provided.
  ```javascript
    // good
    props: {
      foo: {
        type: String,
        required: false,
      }
    }

    // good
    props: {
      foo: {
        type: String,
        required: false,
        default: 'bar'
      }
    }

    // good
    props: {
      foo: {
        type: String,
        required: true
      }
    }
  ```

#### Data
1. `data` method should always be a function

    ```javascript
      // bad
      data: {
        foo: 'foo'
      }

      // good
      data() {
        return {
          foo: 'foo'
        };
      }
    ```

#### Directives

1. Shorthand `@` is preferable over `v-on`
  ```javascript
    // bad
    <component v-on:click="eventHandler"/>


    // good
    <component @click="eventHandler"/>
  ```

1. Shorthand `:` is preferable over `v-bind`
  ```javascript
    // bad
    <component v-bind:class="btn"/>


    // good
    <component :class="btn"/>
  ```

#### Closing tags
1. Prefer self closing component tags
  ```javascript
    // bad
    <component></component>

    // good
    <component />
  ```

#### Ordering

1. Tag order in `.vue` file
    ```
    <script>
      // ...
    </script>

    <template>
      // ...
    </template>

    // We don't use scoped styles but there are few instances of this
    <style>
      // ...
    </style>
    ```

1. Properties in a Vue Component:
  Check [order of properties in components rule][vue-order].

#### `:key`
When using `v-for` you need to provide a *unique* `:key` attribute for each item.

1. If the elements of the array being iterated have an unique `id` it is advised to use it:
    ```html
      <div
        v-for="item in items"
        :key="item.id"
      >
        <!-- content -->
      </div>
    ```

1. When the elements being iterated don't have a unique id, you can use the array index as the `:key` attribute
    ```html
      <div
        v-for="(item, index) in items"
        :key="index"
      >
        <!-- content -->
      </div>
    ```


1. When using `v-for` with `template` and there is more than one child element, the `:key` values must be unique. It's advised to use `kebab-case` namespaces.
    ```html
      <template v-for="(item, index) in items">
        <span :key="`span-${index}`"></span>
        <button :key="`button-${index}`"></button>
      </template>
    ```

1. When dealing with nested `v-for` use the same guidelines as above.
      ```html
        <div
          v-for="item in items"
          :key="item.id"
        >
          <span
            v-for="element in array"
            :key="element.id"
          >
            <!-- content -->
          </span>
        </div>
      ```


Useful links:
1. [`key`](https://vuejs.org/v2/guide/list.html#key)
1. [Vue Style Guide: Keyed v-for](https://vuejs.org/v2/style-guide/#Keyed-v-for-essential )
#### Vue and Bootstrap

1. Tooltips: Do not rely on `has-tooltip` class name for Vue components
  ```javascript
    // bad
    <span
      class="has-tooltip"
      title="Some tooltip text">
      Text
    </span>

    // good
    <span
      v-tooltip
      title="Some tooltip text">
      Text
    </span>
  ```

1. Tooltips: When using a tooltip, include the tooltip directive, `./app/assets/javascripts/vue_shared/directives/tooltip.js`

1. Don't change `data-original-title`.
  ```javascript
    // bad
    <span data-original-title="tooltip text">Foo</span>

    // good
    <span title="tooltip text">Foo</span>

    $('span').tooltip('_fixTitle');
  ```

### The Javascript/Vue Accord
The goal of this accord is to make sure we are all on the same page.

1. When writing Vue, you may not use jQuery in your application.
  1. If you need to grab data from the DOM, you may query the DOM 1 time while bootstrapping your application to grab data attributes using `dataset`. You can do this without jQuery.
  1. You may use a jQuery dependency in Vue.js following [this example from the docs](https://vuejs.org/v2/examples/select2.html).
  1. If an outside jQuery Event needs to be listen to inside the Vue application, you may use jQuery event listeners.
  1. We will avoid adding new jQuery events when they are not required. Instead of adding new jQuery events take a look at [different methods to do the same task](https://vuejs.org/v2/api/#vm-emit).
1. You may query the `window` object 1 time, while bootstrapping your application for application specific data (e.g. `scrollTo` is ok to access anytime). Do this access during the bootstrapping of your application.
1. You may have a temporary but immediate need to create technical debt by writing code that does not follow our standards, to be refactored later. Maintainers need to be ok with the tech debt in the first place. An issue should be created for that tech debt to evaluate it further and discuss. In the coming months you should fix that tech debt, with it's priority to be determined by maintainers.
1. When creating tech debt you must write the tests for that code before hand and those tests may not be rewritten. e.g. jQuery tests rewritten to Vue tests.
1. You may choose to use VueX as a centralized state management. If you choose not to use VueX, you must use the *store pattern* which can be found in the [Vue.js documentation](https://vuejs.org/v2/guide/state-management.html#Simple-State-Management-from-Scratch).
1. Once you have chosen a centralized state management solution you must use it for your entire application. i.e. Don't mix and match your state management solutions.

## SCSS
- [SCSS](style_guide_scss.md)

[airbnb-js-style-guide]: https://github.com/airbnb/javascript
[eslintrc]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/.eslintrc
[eslint-this]: http://eslint.org/docs/rules/class-methods-use-this
[eslint-new]: http://eslint.org/docs/rules/no-new
[eslint-plugin-vue]: https://github.com/vuejs/eslint-plugin-vue
[eslint-plugin-vue-rules]: https://github.com/vuejs/eslint-plugin-vue#bulb-rules
[vue-order]: https://github.com/vuejs/eslint-plugin-vue/blob/master/docs/rules/order-in-components.md
