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
    require('foo');

    // good
    import Foo from 'foo';

    // bad
    module.exports = Foo;

    // good
    export default Foo;
  ```

1. Relative paths: Unless you are writing a test, always reference other scripts using
relative paths instead of `~`
  * In **app/assets/javascripts**:

    ```javascript
      // bad
      import Foo from '~/foo'

      // good
      import Foo from '../foo';
    ```
  * In **spec/javascripts**:

    ```javascript
      // bad
      import Foo from '../../app/assets/javascripts/foo'

      // good
      import Foo from '~/foo';
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

1. Avoid constructors with side-effects

1. Prefer `.map`, `.reduce` or `.filter` over `.forEach`
A forEach will cause side effects, it will be mutating the array being iterated. Prefer using `.map`,
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

#### Basic Rules
1. Only include one Vue.js component per file.
1. Export components as plain objects:
  ```javascript
    export default {
      template: `<h1>I'm a component</h1>
    }
  ```
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
1. **Reference Naming**: Use PascalCase for Vue components and camelCase for their instances:
  ```javascript
    // bad
    import cardBoard from 'cardBoard';

    // good
    import CardBoard from 'cardBoard'

    // bad
    components: {
      CardBoard: CardBoard
    };

    // good
    components: {
      cardBoard: CardBoard
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

    // if props fit in one line then keep it on the same line
    <component bar="bar" />
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

1. Default key should always be provided if the prop is not required:
  ```javascript
    // bad
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
1. Order for a Vue Component:
  1. `name`
  1. `props`
  1. `mixins`
  1. `data`
  1. `components`
  1. `computedProps`
  1. `methods`
  1. `beforeCreate`
  1. `created`
  1. `beforeMount`
  1. `mounted`
  1. `beforeUpdate`
  1. `updated`
  1. `activated`
  1. `deactivated`
  1. `beforeDestroy`
  1. `destroyed`

#### Vue and Boostrap
1. Tooltips: Do not rely on `has-tooltip` class name for vue components
  ```javascript
    // bad
    <span class="has-tooltip">
      Text
    </span>

    // good
    <span data-toggle="tooltip">
      Text
    </span>
  ```

1. Tooltips: When using a tooltip, include the tooltip mixin

1. Don't change `data-original-title`.

## SCSS
- [SCSS](style_guide_scss.md)

[airbnb-js-style-guide]: https://github.com/airbnb/javascript
[eslintrc]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/.eslintrc
[eslint-this]: http://eslint.org/docs/rules/class-methods-use-this
[eslint-new]: http://eslint.org/docs/rules/no-new
