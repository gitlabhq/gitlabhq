# Vue

To get started with Vue, read through [their documentation](https://vuejs.org/v2/guide/).

## Examples

What is described in the following sections can be found in these examples:

- [Web IDE](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/app/assets/javascripts/ide/stores)
- [Security products](https://gitlab.com/gitlab-org/gitlab/tree/master/ee/app/assets/javascripts/vue_shared/security_reports)
- [Registry](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/app/assets/javascripts/registry/stores)

## Vue architecture

All new features built with Vue.js must follow a [Flux architecture](https://facebook.github.io/flux/).
The main goal we are trying to achieve is to have only one data flow and only one data entry.
In order to achieve this goal we use [vuex](#vuex).

You can also read about this architecture in Vue docs about [state management](https://vuejs.org/v2/guide/state-management.html#Simple-State-Management-from-Scratch)
and about [one way data flow](https://vuejs.org/v2/guide/components.html#One-Way-Data-Flow).

### Components and Store

In some features implemented with Vue.js, like the [issue board](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/app/assets/javascripts/boards)
or [environments table](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/app/assets/javascripts/environments)
you can find a clear separation of concerns:

```plaintext
new_feature
├── components
│   └── component.vue
│   └── ...
├── store
│  └── new_feature_store.js
├── index.js
```

_For consistency purposes, we recommend you to follow the same structure._

Let's look into each of them:

### An `index.js` file

This is the index file of your new feature. This is where the root Vue instance
of the new feature should be.

The Store and the Service should be imported and initialized in this file and
provided as a prop to the main component.

Be sure to read about [page-specific JavaScript](./performance.md#page-specific-javascript).

### Bootstrapping Gotchas

#### Providing data from HAML to JavaScript

While mounting a Vue application may be a need to provide data from Rails to JavaScript.
To do that, provide the data through `data` attributes in the HTML element and query them while mounting the application.

_Note:_ You should only do this while initializing the application, because the mounted element will be replaced with Vue-generated DOM.

The advantage of providing data from the DOM to the Vue instance through `props` in the `render` function
instead of querying the DOM inside the main Vue component is that makes tests easier by avoiding the need to
create a fixture or an HTML element in the unit test. See the following example:

```javascript
// haml
.js-vue-app{ data: { endpoint: 'foo' }}

// index.js
document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '.js-vue-app',
  data() {
    const dataset = this.$options.el.dataset;
    return {
      endpoint: dataset.endpoint,
    };
  },
  render(createElement) {
    return createElement('my-component', {
      props: {
        endpoint: this.endpoint,
      },
    });
  },
}));
```

#### Accessing the `gl` object

When we need to query the `gl` object for data that won't change during the application's life cycle, we should do it in the same place where we query the DOM.
By following this practice, we can avoid the need to mock the `gl` object, which will make tests easier.
It should be done while initializing our Vue instance, and the data should be provided as `props` to the main component:

```javascript
document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '.js-vue-app',
  render(createElement) {
    return createElement('my-component', {
      props: {
        username: gon.current_username,
      },
    });
  },
}));
```

#### Accessing feature flags

Use Vue's [provide/inject](https://vuejs.org/v2/api/#provide-inject) mechanism
to make feature flags available to any descendant components in a Vue
application. The `glFeatures` object is already provided in `commons/vue.js`, so
only the mixin is required to utilize the flags:

```javascript
// An arbitrary descendant component

import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  // ...
  mixins: [glFeatureFlagsMixin()],
  // ...
  created() {
    if (this.glFeatures.myFlag) {
      // ...
    }
  },
}
```

This approach has a few benefits:

- Arbitrarily deeply nested components can opt-in and access the flag without
  intermediate components being aware of it (c.f. passing the flag down via
  props).
- Good testability, since the flag can be provided to `mount`/`shallowMount`
  from `vue-test-utils` as easily as a prop.

  ```javascript
  import { shallowMount } from '@vue/test-utils';

  shallowMount(component, {
    provide: {
      glFeatures: { myFlag: true },
    },
  });
  ```

- No need to access a global variable, except in the application's
  [entry point](#accessing-the-gl-object).

### A folder for Components

This folder holds all components that are specific of this new feature.
If you need to use or create a component that will probably be used somewhere
else, please refer to `vue_shared/components`.

A good thumb rule to know when you should create a component is to think if
it will be reusable elsewhere.

For example, tables are used in a quite amount of places across GitLab, a table
would be a good fit for a component. On the other hand, a table cell used only
in one table would not be a good use of this pattern.

You can read more about components in Vue.js site, [Component System](https://vuejs.org/v2/guide/#Composing-with-Components).

### A folder for the Store

#### Vuex

Check this [page](vuex.md) for more details.

### Mixing Vue and jQuery

- Mixing Vue and jQuery is not recommended.
- If you need to use a specific jQuery plugin in Vue, [create a wrapper around it](https://vuejs.org/v2/examples/select2.html).
- It is acceptable for Vue to listen to existing jQuery events using jQuery event listeners.
- It is not recommended to add new jQuery events for Vue to interact with jQuery.

## Style guide

Please refer to the Vue section of our [style guide](style/vue.md)
for best practices while writing your Vue components and templates.

## Testing Vue Components

Each Vue component has a unique output. This output is always present in the render function.

Although we can test each method of a Vue component individually, our goal must be to test the output
of the render/template function, which represents the state at all times.

Here's an example of a well structured unit test for [this Vue component](#appendix---vue-component-subject-under-test):

```javascript
import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import App from '~/todos/app.vue';

const TEST_TODOS = [
  { text: 'Lorem ipsum test text' },
  { text: 'Lorem ipsum 2' },
];
const TEST_NEW_TODO = 'New todo title';
const TEST_TODO_PATH = '/todos';

describe('~/todos/app.vue', () => {
  let wrapper;
  let mock;

  beforeEach(() => {
    // IMPORTANT: Use axios-mock-adapter for stubbing axios API requests
    mock = new MockAdapter(axios);
    mock.onGet(TEST_TODO_PATH).reply(200, TEST_TODOS);
    mock.onPost(TEST_TODO_PATH).reply(200);
  });

  afterEach(() => {
    // IMPORTANT: Clean up the component instance and axios mock adapter
    wrapper.destroy();
    wrapper = null;

    mock.restore();
  });

  // NOTE: It is very helpful to separate setting up the component from
  // its collaborators (i.e. Vuex, axios, etc.)
  const createWrapper = (props = {}) => {
    wrapper = shallowMount(App, {
      propsData: {
        path: TEST_TODO_PATH,
        ...props,
      },
    });
  };
  // NOTE: Helper methods greatly help test maintainability and readability.
  const findLoader = () => wrapper.find(GlLoadingIcon);
  const findAddButton = () => wrapper.find('[data-testid="add-button"]');
  const findTextInput = () => wrapper.find('[data-testid="text-input"]');
  const findTodoData = () => wrapper.findAll('[data-testid="todo-item"]').wrappers.map(wrapper => ({ text: wrapper.text() }));

  describe('when mounted and loading', () => {
    beforeEach(() => {
      // Create request which will never resolve
      mock.onGet(TEST_TODO_PATH).reply(() => new Promise(() => {}));
      createWrapper();
    });

    it('should render the loading state', () => {
      expect(findLoader().exists()).toBe(true);
    });
  });

  describe('when todos are loaded', () => {
    beforeEach(() => {
      createWrapper();
      // IMPORTANT: This component fetches data asynchronously on mount, so let's wait for the Vue template to update
      return wrapper.vm.$nextTick();
    });

    it('should not show loading', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('should render todos', () => {
      expect(findTodoData()).toEqual(TEST_TODOS);
    });

    it('when todo is added, should post new todo', () => {
      findTextInput().vm.$emit('update', TEST_NEW_TODO)
      findAddButton().vm.$emit('click');

      return wrapper.vm.$nextTick()
        .then(() => {
          expect(mock.history.post.map(x => JSON.parse(x.data))).toEqual([{ text: TEST_NEW_TODO }]);
        });
    });
  });
});
```

### Test the component's output

The main return value of a Vue component is the rendered output. In order to test the component we
need to test the rendered output. [Vue](https://vuejs.org/v2/guide/unit-testing.html) guide's to unit test show us exactly that:

### Events

We should test for events emitted in response to an action within our component, this is useful to verify the correct events are being fired with the correct arguments.

For any DOM events we should use [`trigger`](https://vue-test-utils.vuejs.org/api/wrapper/#trigger) to fire out event.

```javascript
// Assuming SomeButton renders: <button>Some button</button>
wrapper = mount(SomeButton);

...
it('should fire the click event', () => {
  const btn = wrapper.find('button')

  btn.trigger('click');
  ...
})
```

When we need to fire a Vue event, we should use [`emit`](https://vuejs.org/v2/guide/components-custom-events.html) to fire our event.

```javascript
wrapper = shallowMount(DropdownItem);

...

it('should fire the itemClicked event', () => {
  DropdownItem.vm.$emit('itemClicked');
  ...
})
```

We should verify an event has been fired by asserting against the result of the [`emitted()`](https://vue-test-utils.vuejs.org/api/wrapper/#emitted) method

## Vue.js Expert Role

One should apply to be a Vue.js expert by opening an MR when the Merge Request's they create and review show:

- Deep understanding of Vue and Vuex reactivity
- Vue and Vuex code are structured according to both official and our guidelines
- Full understanding of testing a Vue and Vuex application
- Vuex code follows the [documented pattern](vuex.md#naming-pattern-request-and-receive-namespaces)
- Knowledge about the existing Vue and Vuex applications and existing reusable components

## Vue 2 -> Vue 3 Migration

> This section is added temporarily to support the efforts to migrate the codebase from Vue 2.x to Vue 3.x

Currently, we recommend to minimize adding certain features to the codebase to prevent increasing the tech debt for the eventual migration:

- filters;
- event buses;
- functional templated
- `slot` attributes

You can find more details on [Migration to Vue 3](vue3_migration.md)

## Appendix - Vue component subject under test

This is the template for the example component which is tested in the [Testing Vue components](#testing-vue-components) section:

```html
<template>
  <div class="content">
    <gl-loading-icon v-if="isLoading" />
    <template v-else>
      <div
        v-for="todo in todos"
        :key="todo.id"
        :class="{ 'gl-strike': todo.isDone }"
        data-testid="todo-item"
      >{{ toddo.text }}</div>
      <footer class="gl-border-t-1 gl-mt-3 gl-pt-3">
        <gl-form-input
          type="text"
          v-model="todoText"
          data-testid="text-input"
        >
        <gl-button
          variant="success"
          data-testid="add-button"
          @click="addTodo"
        >Add</gl-button>
      </footer>
    </template>
  </div>
</template>
```
