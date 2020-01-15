# Vue.js style guide

## Linting

We default to [eslint-vue-plugin](https://github.com/vuejs/eslint-plugin-vue), with the `plugin:vue/recommended`.
Please check this [rules](https://github.com/vuejs/eslint-plugin-vue#bulb-rules) for more documentation.

## Basic Rules

1. The service has its own file
1. The store has its own file
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

1. Do not use a singleton for the service or the store

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

1. Use `.vue` for Vue templates. Do not use `%template` in HAML.

## Naming

1. **Extensions**: Use `.vue` extension for Vue components. Do not use `.js` as file extension ([#34371]).
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

[#34371]: https://gitlab.com/gitlab-org/gitlab-foss/issues/34371

## Alignment

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

## Quotes

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

## Props

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

## Data

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

## Directives

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

1. Shorthand `#` is preferable over `v-slot`

   ```javascript
   // bad
   <template v-slot:header></template>

   // good
   <template #header></template>
   ```

## Closing tags

1. Prefer self-closing component tags

   ```javascript
   // bad
   <component></component>

   // good
   <component />
   ```

## Component usage within templates

1. Prefer a component's kebab-cased name over other styles when using it in a template

   ```javascript
   // bad
   <MyComponent />

   // good
   <my-component />
   ```

## Ordering

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
   Check [order of properties in components rule](https://github.com/vuejs/eslint-plugin-vue/blob/master/docs/rules/order-in-components.md).

## `:key`

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

## Vue and Bootstrap

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

## The JavaScript/Vue Accord

The goal of this accord is to make sure we are all on the same page.

1. When writing Vue, you may not use jQuery in your application.
   1. If you need to grab data from the DOM, you may query the DOM 1 time while bootstrapping your application to grab data attributes using `dataset`. You can do this without jQuery.
   1. You may use a jQuery dependency in Vue.js following [this example from the docs](https://vuejs.org/v2/examples/select2.html).
   1. If an outside jQuery Event needs to be listen to inside the Vue application, you may use jQuery event listeners.
   1. We will avoid adding new jQuery events when they are not required. Instead of adding new jQuery events take a look at [different methods to do the same task](https://vuejs.org/v2/api/#vm-emit).
1. You may query the `window` object one time, while bootstrapping your application for application specific data (e.g. `scrollTo` is ok to access anytime). Do this access during the bootstrapping of your application.
1. You may have a temporary but immediate need to create technical debt by writing code that does not follow our standards, to be refactored later. Maintainers need to be ok with the tech debt in the first place. An issue should be created for that tech debt to evaluate it further and discuss. In the coming months you should fix that tech debt, with its priority to be determined by maintainers.
1. When creating tech debt you must write the tests for that code before hand and those tests may not be rewritten. e.g. jQuery tests rewritten to Vue tests.
1. You may choose to use VueX as a centralized state management. If you choose not to use VueX, you must use the *store pattern* which can be found in the [Vue.js documentation](https://vuejs.org/v2/guide/state-management.html#Simple-State-Management-from-Scratch).
1. Once you have chosen a centralized state-management solution you must use it for your entire application. i.e. Don't mix and match your state-management solutions.
