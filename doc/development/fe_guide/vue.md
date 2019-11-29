# Vue

To get started with Vue, read through [their documentation](https://vuejs.org/v2/guide/).

## Examples

What is described in the following sections can be found in these examples:

- web ide: <https://gitlab.com/gitlab-org/gitlab-foss/tree/master/app/assets/javascripts/ide/stores>
- security products: <https://gitlab.com/gitlab-org/gitlab/tree/master/ee/app/assets/javascripts/vue_shared/security_reports>
- registry: <https://gitlab.com/gitlab-org/gitlab-foss/tree/master/app/assets/javascripts/registry/stores>

## Vue architecture

All new features built with Vue.js must follow a [Flux architecture][flux].
The main goal we are trying to achieve is to have only one data flow and only one data entry.
In order to achieve this goal we use [vuex](#vuex).

You can also read about this architecture in vue docs about [state management][state-management]
and about [one way data flow][one-way-data-flow].

### Components and Store

In some features implemented with Vue.js, like the [issue board][issue-boards]
or [environments table][environments-table]
you can find a clear separation of concerns:

```
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

Be sure to read about [page-specific JavaScript][page_specific_javascript].

### Bootstrapping Gotchas

#### Providing data from HAML to JavaScript

While mounting a Vue application may be a need to provide data from Rails to JavaScript.
To do that, provide the data through `data` attributes in the HTML element and query them while mounting the application.

_Note:_ You should only do this while initializing the application, because the mounted element will be replaced with Vue-generated DOM.

The advantage of providing data from the DOM to the Vue instance through `props` in the `render` function
instead of querying the DOM inside the main vue component is that makes tests easier by avoiding the need to
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
        endpoint: this.isLoading,
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

You can read more about components in Vue.js site, [Component System][component-system]

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

Make use of the [axios mock adapter](axios.md#mock-axios-response-in-tests) to mock data returned.

Here's how we would test the Todo App above:

```javascript
import Vue from 'vue';
import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';

describe('Todos App', () => {
  let vm;
  let mock;

  beforeEach(() => {
    // Create a mock adapter for stubbing axios API requests
    mock = new MockAdapter(axios);

    const Component = Vue.extend(component);

    // Mount the Component
    vm = new Component().$mount();
  });

  afterEach(() => {
    // Reset the mock adapter
    mock.restore();
    // Destroy the mounted component
    vm.$destroy();
  });

  it('should render the loading state while the request is being made', () => {
    expect(vm.$el.querySelector('i.fa-spin')).toBeDefined();
  });

  it('should render todos returned by the endpoint', done => {
    // Mock the get request on the API endpoint to return data
    mock.onGet('/todos').replyOnce(200, [
      {
        title: 'This is a todo',
        text: 'This is the text',
      },
    ]);

    Vue.nextTick(() => {
      const items = vm.$el.querySelectorAll('.js-todo-list div')
      expect(items.length).toBe(1);
      expect(items[0].textContent).toContain('This is the text');
      done();
    });
  });

  it('should add a todos on button click', (done) => {

    // Mock the put request and check that the sent data object is correct
    mock.onPut('/todos').replyOnce((req) => {
      expect(req.data).toContain('text');
      expect(req.data).toContain('title');

      return [201, {}];
    });

    vm.$el.querySelector('.js-add-todo').click();

    // Add a new interceptor to mock the add Todo request
    Vue.nextTick(() => {
      expect(vm.$el.querySelectorAll('.js-todo-list div').length).toBe(2);
      done();
    });
  });
});
```

### `mountComponent` helper

There is a helper in `spec/javascripts/helpers/vue_mount_component_helper.js` that allows you to mount a component with the given props:

```javascript
import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper'
import component from 'component.vue'

const Component = Vue.extend(component);
const data = {prop: 'foo'};
const vm = mountComponent(Component, data);
```

### Test the component's output

The main return value of a Vue component is the rendered output. In order to test the component we
need to test the rendered output. [Vue][vue-test] guide's to unit test show us exactly that:

## Vue.js Expert Role

One should apply to be a Vue.js expert by opening an MR when the Merge Request's they create and review show:

- Deep understanding of Vue and Vuex reactivity
- Vue and Vuex code are structured according to both official and our guidelines
- Full understanding of testing a Vue and Vuex application
- Vuex code follows the [documented pattern](vuex.md#actions-pattern-request-and-receive-namespaces)
- Knowledge about the existing Vue and Vuex applications and existing reusable components

[issue-boards]: https://gitlab.com/gitlab-org/gitlab-foss/tree/master/app/assets/javascripts/boards
[environments-table]: https://gitlab.com/gitlab-org/gitlab-foss/tree/master/app/assets/javascripts/environments
[page_specific_javascript]: ./performance.md#page-specific-javascript
[component-system]: https://vuejs.org/v2/guide/#Composing-with-Components
[state-management]: https://vuejs.org/v2/guide/state-management.html#Simple-State-Management-from-Scratch
[one-way-data-flow]: https://vuejs.org/v2/guide/components.html#One-Way-Data-Flow
[vue-test]: https://vuejs.org/v2/guide/unit-testing.html
[flux]: https://facebook.github.io/flux/
[axios]: https://github.com/axios/axios
