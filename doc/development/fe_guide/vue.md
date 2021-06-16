---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Vue

To get started with Vue, read through [their documentation](https://vuejs.org/v2/guide/).

## Examples

What is described in the following sections can be found in these examples:

- [Web IDE](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/app/assets/javascripts/ide/stores)
- [Security products](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/app/assets/javascripts/vue_shared/security_reports)
- [Registry](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/app/assets/javascripts/registry/stores)

## Vue architecture

All new features built with Vue.js must follow a [Flux architecture](https://facebook.github.io/flux/).
The main goal we are trying to achieve is to have only one data flow and only one data entry.
In order to achieve this goal we use [Vuex](#vuex).

You can also read about this architecture in Vue documentation about
[state management](https://vuejs.org/v2/guide/state-management.html#Simple-State-Management-from-Scratch)
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

Be sure to read about [page-specific JavaScript](performance.md#page-specific-javascript).

### Bootstrapping Gotchas

#### Providing data from HAML to JavaScript

While mounting a Vue application, you might need to provide data from Rails to JavaScript.
To do that, you can use the `data` attributes in the HTML element and query them while mounting the application.

You should only do this while initializing the application, because the mounted element is replaced
with a Vue-generated DOM.

The advantage of providing data from the DOM to the Vue instance through `props` in the `render`
function instead of querying the DOM inside the main Vue component is avoiding the need to create a
fixture or an HTML element in the unit test, which makes the tests easier.

See the following example. Also, please refer to our [Vue style guide](style/vue.md#basic-rules) for
additional information on why we explicitly declare the data being passed into the Vue app;

```javascript
// haml
#js-vue-app{ data: { endpoint: 'foo' }}

// index.js
const el = document.getElementById('js-vue-app');

if (!el) return false;

const { endpoint } = el.dataset;

return new Vue({
  el,
  render(createElement) {
    return createElement('my-component', {
      props: {
        endpoint
      },
    });
  },
});
```

> When adding an `id` attribute to mount a Vue application, please make sure this `id` is unique
across the codebase.

#### Providing Rails form fields to Vue applications

When composing a form with Rails, the `name`, `id`, and `value` attributes of form inputs are generated
to match the backend. It can be helpful to have access to these generated attributes when converting
a Rails form to Vue, or when [integrating components (datepicker, project selector, etc)](https://gitlab.com/gitlab-org/gitlab/-/blob/8956ad767d522f37a96e03840595c767de030968/app/assets/javascripts/access_tokens/index.js#L15) into it.
The [`parseRailsFormFields`](https://gitlab.com/gitlab-org/gitlab/-/blob/fe88797f682c7ff0b13f2c2223a3ff45ada751c1/app/assets/javascripts/lib/utils/forms.js#L107) utility can be used to parse the generated form input attributes so they can be passed to the Vue application.
This allows us to easily integrate Vue components without changing how the form submits.

```haml
-# form.html.haml
= form_for user do |form|
  .js-user-form
    = form.text_field :name, class: 'form-control gl-form-input', data: { js_name: 'name' }
    = form.text_field :email, class: 'form-control gl-form-input', data: { js_name: 'email' }
```

> The `js_name` data attribute is used as the key in the resulting JavaScript object.
For example `= form.text_field :email, data: { js_name: 'fooBarBaz' }` would be translated
to `{ fooBarBaz: { name: 'user[email]', id: 'user_email', value: '' } }`

```javascript
// index.js
import Vue from 'vue';
import { parseRailsFormFields } from '~/lib/utils/forms';
import UserForm from './components/user_form.vue';

export const initUserForm = () => {
  const el = document.querySelector('.js-user-form');

  if (!el) {
    return null;
  }

  const fields = parseRailsFormFields(el);

  return new Vue({
    el,
    render(h) {
      return h(UserForm, {
        props: {
          fields,
        },
      });
    },
  });
};
```

```vue
<script>
// user_form.vue
import { GlButton, GlFormGroup, GlFormInput } from '@gitlab/ui';

export default {
  name: 'UserForm',
  components: { GlButton, GlFormGroup, GlFormInput },
  props: {
    fields: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <gl-form-group :label-for="fields.name.id" :label="__('Name')">
      <gl-form-input v-bind="fields.name" size="lg" />
    </gl-form-group>

    <gl-form-group :label-for="fields.email.id" :label="__('Email')">
      <gl-form-input v-bind="fields.email" type="email" size="lg" />
    </gl-form-group>

    <gl-button type="submit" category="primary" variant="confirm">{{ __('Update') }}</gl-button>
  </div>
</template>
```

#### Accessing the `gl` object

We query the `gl` object for data that doesn't change during the application's life
cycle in the same place we query the DOM. By following this practice, we can
avoid the need to mock the `gl` object, which makes tests easier. It should be done while
initializing our Vue instance, and the data should be provided as `props` to the main component:

```javascript
return new Vue({
  el: '.js-vue-app',
  render(createElement) {
    return createElement('my-component', {
      props: {
        username: gon.current_username,
      },
    });
  },
});
```

#### Accessing feature flags

Use Vue's [provide/inject](https://vuejs.org/v2/api/#provide-inject) mechanism
to make feature flags available to any descendant components in a Vue
application. The `glFeatures` object is already provided in `commons/vue.js`, so
only the mixin is required to use the flags:

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
- Good testability, because the flag can be provided to `mount`/`shallowMount`
  from `vue-test-utils` as a prop.

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

This folder holds all components that are specific to this new feature.
If you need to use or create a component that is likely to be used somewhere
else, please refer to `vue_shared/components`.

A good rule of thumb to know when you should create a component is to think if
it could be reusable elsewhere.

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

### Mixing Vue and JavaScript classes (in the data function)

In the [Vue documentation](https://vuejs.org/v2/api/#Options-Data) the Data function/object is defined as follows:

> The data object for the Vue instance. Vue recursively converts its properties into getter/setters
to make it "reactive". The object must be plain: native objects such as browser API objects and
prototype properties are ignored. A rule of thumb is that data should just be data - it is not
recommended to observe objects with their own stateful behavior.

Based on the Vue guidance:

- **Do not** use or create a JavaScript class in your [data function](https://vuejs.org/v2/api/#data),
such as `user: new User()`.
- **Do not** add new JavaScript class implementations.
- **Do** use [GraphQL](../api_graphql_styleguide.md), [Vuex](vuex.md) or a set of components if
cannot use primitives or objects.
- **Do** maintain existing implementations using such approaches.
- **Do** Migrate components to a pure object model when there are substantial changes to it.
- **Do** add business logic to helpers or utilities, so you can test them separately from your component.

#### Why

There are additional reasons why having a JavaScript class presents maintainability issues on a huge codebase:

- After a class is created, it can be extended in a way that can infringe Vue reactivity and best practices.
- A class adds a layer of abstraction, which makes the component API and its inner workings less clear.
- It makes it harder to test. Because the class is instantiated by the component data function, it is
harder to 'manage' component and class separately.
- Adding Object Oriented Principles (OOP) to a functional codebase adds yet another way of writing code, reducing consistency and clarity.

## Style guide

Please refer to the Vue section of our [style guide](style/vue.md)
for best practices while writing and testing your Vue components and templates.

## Testing Vue Components

Please refer to the [Vue testing style guide](style/vue.md#vue-testing)
for guidelines and best practices for testing your Vue components.

Each Vue component has a unique output. This output is always present in the render function.

Although each method of a Vue component can be tested individually, our goal is to test the output
of the render function, which represents the state at all times.

Visit the [Vue testing guide](https://vuejs.org/v2/guide/testing.html#Unit-Testing) for help
testing the rendered output.

Here's an example of a well structured unit test for [this Vue component](#appendix---vue-component-subject-under-test):

```javascript
import { GlLoadingIcon } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import App from '~/todos/app.vue';

const TEST_TODOS = [{ text: 'Lorem ipsum test text' }, { text: 'Lorem ipsum 2' }];
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
    mock.restore();
  });

  // It is very helpful to separate setting up the component from
  // its collaborators (for example, Vuex and axios).
  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(App, {
      propsData: {
        path: TEST_TODO_PATH,
        ...props,
      },
    });
  };
  // Helper methods greatly help test maintainability and readability.
  const findLoader = () => wrapper.findComponent(GlLoadingIcon);
  const findAddButton = () => wrapper.findByTestId('add-button');
  const findTextInput = () => wrapper.findByTestId('text-input');
  const findTodoData = () =>
    wrapper
      .findAllByTestId('todo-item')
      .wrappers.map((item) => ({ text: item.text() }));

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

    it('when todo is added, should post new todo', async () => {
      findTextInput().vm.$emit('update', TEST_NEW_TODO);
      findAddButton().vm.$emit('click');

      await wrapper.vm.$nextTick();

      expect(mock.history.post.map((x) => JSON.parse(x.data))).toEqual([{ text: TEST_NEW_TODO }]);
    });
  });
});
```

### Child components

1. Test any directive that defines if/how child component is rendered (for example, `v-if` and `v-for`).
1. Test any props we are passing to child components (especially if the prop is calculated in the
component under test, with the `computed` property, for example). Remember to use `.props()` and not `.vm.someProp`.
1. Test we react correctly to any events emitted from child components:

  ```javascript
  const checkbox = wrapper.findByTestId('checkboxTestId');

  expect(checkbox.attributes('disabled')).not.toBeDefined();

  findChildComponent().vm.$emit('primary');
  await nextTick();

  expect(checkbox.attributes('disabled')).toBeDefined();
  ```

1. **Do not** test the internal implementation of the child components:

  ```javascript
  // bad
  expect(findChildComponent().find('.error-alert').exists()).toBe(false);

  // good
  expect(findChildComponent().props('withAlertContainer')).toBe(false);
  ```

### Events

We should test for events emitted in response to an action in our component. This is used to
verify the correct events are being fired with the correct arguments.

For any DOM events we should use [`trigger`](https://vue-test-utils.vuejs.org/api/wrapper/#trigger)
to fire out event.

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

When we need to fire a Vue event, we should use [`emit`](https://vuejs.org/v2/guide/components-custom-events.html)
to fire our event.

```javascript
wrapper = shallowMount(DropdownItem);

...

it('should fire the itemClicked event', () => {
  DropdownItem.vm.$emit('itemClicked');
  ...
})
```

We should verify an event has been fired by asserting against the result of the
[`emitted()`](https://vue-test-utils.vuejs.org/api/wrapper/#emitted) method.

## Vue.js Expert Role

You should only apply to be a Vue.js expert when your own merge requests and your reviews show:

- Deep understanding of Vue and Vuex reactivity
- Vue and Vuex code are structured according to both official and our guidelines
- Full understanding of testing a Vue and Vuex application
- Vuex code follows the [documented pattern](vuex.md#naming-pattern-request-and-receive-namespaces)
- Knowledge about the existing Vue and Vuex applications and existing reusable components

## Vue 2 -> Vue 3 Migration

> This section is added temporarily to support the efforts to migrate the codebase from Vue 2.x to Vue 3.x

We recommend to minimize adding certain features to the codebase to prevent increasing
the tech debt for the eventual migration:

- filters;
- event buses;
- functional templated
- `slot` attributes

You can find more details on [Migration to Vue 3](vue3_migration.md)

## Appendix - Vue component subject under test

This is the template for the example component which is tested in the
[Testing Vue components](#testing-vue-components) section:

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
