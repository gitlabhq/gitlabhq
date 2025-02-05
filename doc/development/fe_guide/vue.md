---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Vue
---

To get started with Vue, read through [their documentation](https://v2.vuejs.org/v2/guide/index.html).

## Examples

What is described in the following sections can be found in these examples:

- [Web IDE](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/app/assets/javascripts/ide/stores)
- [Security products](https://gitlab.com/gitlab-org/gitlab/-/tree/master/ee/app/assets/javascripts/vue_shared/security_reports)
- [Registry](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/app/assets/javascripts/registry/stores)

## When to add Vue application

Sometimes, HAML page is enough to satisfy requirements. This statement is correct primarily for the static pages or pages that have very little logic. How do we know it's worth adding a Vue application to the page? The answer is "when we need to maintain application state and synchronize the rendered page with it".

To better explain this, let's imagine the page that has one toggle, and toggling it sends an API request. This case does not involve any state we want to maintain, we send the request and switch the toggle. However, if we add one more toggle that should always be the opposite to the first one, we need a _state_: one toggle should be "aware" about the state of another one. When written in plain JavaScript, this logic usually involves listening to DOM event and reacting with modifying DOM. Cases like this are much easier to handle with Vue.js so we should create a Vue application here.

### What are some flags signaling that you might need Vue application?

- when you need to define complex conditionals based on multiple factors and update them on user interaction;
- when you have to maintain any form of application state and share it between tags/elements;
- when you expect complex logic to be added in the future - it's easier to start with basic Vue application than having to rewrite JS/HAML to Vue on the next step.

## Avoid multiple Vue applications on the page

In the past, we added interactivity to the page piece-by-piece, adding multiple small Vue applications to different parts of the rendered HAML page. However, this approach led us to multiple complications:

- in most cases, these applications don't share state and perform API requests independently which grows a number of requests;
- we have to provide data from Rails to Vue using multiple endpoints;
- we cannot render Vue applications dynamically after page load, so the page structure becomes rigid;
- we cannot fully leverage client-side routing to replace Rails routing;
- multiple applications lead to unpredictable user experience, increased page complexity, harder debugging process;
- the way apps communicate with each other affects Web Vitals numbers.

Because of these reasons, we want to be cautious about adding new Vue applications to the pages where another Vue application is already present (this does not include old or new navigation). Before adding a new app, make sure that it is absolutely impossible to extend an existing application to achieve a desired functionality. When in doubt, feel free to ask for the architectural advise on `#frontend` or `#frontend-maintainers` Slack channel.

If you still need to add a new application, make sure it shares local state with existing applications.
Learn: [How do I know which state manager to use?](state_management.md)

## Vue architecture

The main goal we are trying to achieve with Vue architecture is to have only one data flow, and only one data entry.
To achieve this goal we use [Pinia](pinia.md) or [Apollo Client](graphql.md#libraries)

You can also read about this architecture in Vue documentation about
[state management](https://v2.vuejs.org/v2/guide/state-management.html#Simple-State-Management-from-Scratch)
and about [one way data flow](https://v2.vuejs.org/v2/guide/components-props.html#One-Way-Data-Flow).

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

This file is the index file of your new feature. The root Vue instance
of the new feature should be here.

The Store and the Service should be imported and initialized in this file and
provided as a prop to the main component.

Be sure to read about [page-specific JavaScript](performance.md#page-specific-javascript).

### Bootstrapping Gotchas

#### Providing data from HAML to JavaScript

While mounting a Vue application, you might need to provide data from Rails to JavaScript.
To do that, you can use the `data` attributes in the HTML element and query them while mounting the application.
You should only do this while initializing the application, because the mounted element is replaced
with a Vue-generated DOM.

The `data` attributes are [only able to accept String values](https://developer.mozilla.org/en-US/docs/Learn/HTML/Howto/Use_data_attributes#javascript_access),
so you will need to cast or convert other variable types to String.

The advantage of providing data from the DOM to the Vue instance through `props` or
`provide` in the `render` function, instead of querying the DOM inside the main Vue
component, is that you avoid creating a fixture or an HTML element in the unit test.

##### The `initSimpleApp` helper

`initSimpleApp` is a helper function that streamlines the process of mounting a component in Vue.js. It accepts two arguments: a selector string representing the mount point in the HTML, and a Vue component.

To use `initSimpleApp`:

1. Include an HTML element in the page with an ID or unique class.
1. Add a data-view-model attribute containing a JSON object.
1. Import the desired Vue component, and pass it along with a valid CSS selector string
   that selects the HTML element to `initSimpleApp`. This string mounts the component
   at the specified location.

`initSimpleApp` automatically retrieves the content of the data-view-model attribute as a JSON object and passes it as props to the mounted Vue component. This can be used to pre-populate the component with data.

Example:

```vue
//my_component.vue
<template>
  <div>
    <p>Prop1: {{ prop1 }}</p>
    <p>Prop2: {{ prop2 }}</p>
  </div>
</template>

<script>
export default {
  name: 'MyComponent',
  props: {
    prop1: {
      type: String,
      required: true
    },
    prop2: {
      type: Number,
      required: true
    }
  }
}
</script>
```

```html
<div id="js-my-element" data-view-model='{"prop1": "my object", "prop2": 42 }'></div>
```

```javascript
//index.js
import MyComponent from './my_component.vue'
import { initSimpleApp } from '~/helpers/init_simple_app_helper'

initSimpleApp('#js-my-element', MyComponent, { name: 'MyAppRoot' })
```

##### `provide` and `inject`

Vue supports dependency injection through [`provide` and `inject`](https://v2.vuejs.org/v2/api/#provide-inject).
In the component the `inject` configuration accesses the values `provide` passes down.
This example of a Vue app initialization shows how the `provide` configuration passes a value from HAML to the component:

```javascript
#js-vue-app{ data: { endpoint: 'foo' }}

// index.js
const el = document.getElementById('js-vue-app');

if (!el) return false;

const { endpoint } = el.dataset;

return new Vue({
  el,
  name: 'MyComponentRoot',
  render(createElement) {
    return createElement('my-component', {
      provide: {
        endpoint
      },
    });
  },
});
```

The component, or any of its child components, can access the property through `inject` as:

```vue
<script>
  export default {
    name: 'MyComponent',
    inject: ['endpoint'],
    ...
    ...
  };
</script>
<template>
  ...
  ...
</template>
```

Using dependency injection to provide values from HAML is ideal when:

- The injected value doesn't need an explicit validation against its data type or contents.
- The value doesn't need to be reactive.
- Multiple components exist in the hierarchy that need access to this value where
  prop-drilling becomes an inconvenience. Prop-drilling when the same prop is passed
  through all components in the hierarchy until the component that is genuinely using it.

Dependency injection can potentially break a child component (either an immediate child or multiple levels deep) if both conditions are true:

- The value declared in the `inject` configuration doesn't have defaults defined.
- The parent component has not provided the value using the `provide` configuration.

A [default value](https://vuejs.org/guide/components/provide-inject.html#injection-default-values) might be useful in contexts where it makes sense.

##### props

If the value from HAML doesn't fit the criteria of dependency injection, use `props`.
See the following example.

```javascript
// haml
#js-vue-app{ data: { endpoint: 'foo' }}

// index.js
const el = document.getElementById('js-vue-app');

if (!el) return false;

const { endpoint } = el.dataset;

return new Vue({
  el,
  name: 'MyComponentRoot',
  render(createElement) {
    return createElement('my-component', {
      props: {
        endpoint
      },
    });
  },
});
```

NOTE:
When adding an `id` attribute to mount a Vue application, make sure this `id` is unique
across the codebase.

For more information on why we explicitly declare the data being passed into the Vue app,
refer to our [Vue style guide](style/vue.md#basic-rules).

#### Providing Rails form fields to Vue applications

When composing a form with Rails, the `name`, `id`, and `value` attributes of form inputs are generated
to match the backend. It can be helpful to have access to these generated attributes when converting
a Rails form to Vue, or when [integrating components](https://gitlab.com/gitlab-org/gitlab/-/blob/8956ad767d522f37a96e03840595c767de030968/app/assets/javascripts/access_tokens/index.js#L15) (such as a date picker or project selector) into it.
The [`parseRailsFormFields`](https://gitlab.com/gitlab-org/gitlab/-/blob/fe88797f682c7ff0b13f2c2223a3ff45ada751c1/app/assets/javascripts/lib/utils/forms.js#L107) utility function can be used to parse the generated form input attributes so they can be passed to the Vue application.
This enables us to integrate Vue components without changing how the form submits.

```haml
-# form.html.haml
= form_for user do |form|
  .js-user-form
    = form.text_field :name, class: 'form-control gl-form-input', data: { js_name: 'name' }
    = form.text_field :email, class: 'form-control gl-form-input', data: { js_name: 'email' }
```

The `js_name` data attribute is used as the key in the resulting JavaScript object.
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
    name: 'UserFormRoot',
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
      <gl-form-input v-bind="fields.name" width="lg" />
    </gl-form-group>

    <gl-form-group :label-for="fields.email.id" :label="__('Email')">
      <gl-form-input v-bind="fields.email" type="email" width="lg" />
    </gl-form-group>

    <gl-button type="submit" category="primary" variant="confirm">{{ __('Update') }}</gl-button>
  </div>
</template>
```

#### Accessing the `gl` object

We query the `gl` object for data that doesn't change during the application's life
cycle in the same place we query the DOM. By following this practice, we can
avoid mocking the `gl` object, which makes tests easier. It should be done while
initializing our Vue instance, and the data should be provided as `props` to the main component:

```javascript
return new Vue({
  el: '.js-vue-app',
  name: 'MyComponentRoot',
  render(createElement) {
    return createElement('my-component', {
      props: {
        avatarUrl: gl.avatarUrl,
      },
    });
  },
});
```

#### Accessing abilities

After pushing an ability to the [frontend](../permissions/authorizations.md#frontend),
use the [`provide` and `inject`](https://v2.vuejs.org/v2/api/#provide-inject)
mechanisms in Vue to make abilities available to any descendant components
in a Vue application. The `glAbilties` object is already provided in
`commons/vue.js`, so only the mixin is required to use the flags:

```javascript
// An arbitrary descendant component

import glAbilitiesMixin from '~/vue_shared/mixins/gl_abilities_mixin';

export default {
  // ...
  mixins: [glAbilitiesMixin()],
  // ...
  created() {
    if (this.glAbilities.someAbility) {
      // ...
    }
  },
}
```

#### Accessing feature flags

After pushing a feature flag to the [frontend](../feature_flags/_index.md#frontend),
use the [`provide` and `inject`](https://v2.vuejs.org/v2/api/#provide-inject)
mechanisms in Vue to make feature flags available to any descendant components
in a Vue application. The `glFeatures` object is already provided in
`commons/vue.js`, so only the mixin is required to use the flags:

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

- Accessing a global variable is not required, except in the application's
  [entry point](#accessing-the-gl-object).

#### Redirecting to page and displaying alerts

If you need to redirect to another page and display alerts, you can use the [`visitUrlWithAlerts`](https://gitlab.com/gitlab-org/gitlab/-/blob/7063dce68b8231442567707024b2f29e48ce2f64/app/assets/javascripts/lib/utils/url_utility.js#L731) utility function.
This can be useful when you're redirecting to a newly created resource and showing a success alert.

By default the alerts will be cleared when the page is reloaded. If you need an alert to be persisted on a page you can set the
`persistOnPages` key to an array of Rails controller actions. To find the Rails controller action run `document.body.dataset.page` in your console.

Example:

```javascript
visitUrlWithAlerts('/dashboard/groups', [
  {
    id: 'resource-building-in-background',
    message: 'Resource is being built in the background.',
    variant: 'info',
    persistOnPages: ['dashboard:groups:index'],
  },
])
```

If you need to manually remove a persisted alert, you can use the [`removeGlobalAlertById`](https://gitlab.com/gitlab-org/gitlab/-/blob/7063dce68b8231442567707024b2f29e48ce2f64/app/assets/javascripts/lib/utils/global_alerts.js#L31) utility function.

If you need to programmatically dismiss an alert, you can use the [`dismissGlobalAlertById`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/assets/javascripts/lib/utils/global_alerts.js#L43) utility function.

### A folder for Components

This folder holds all components that are specific to this new feature.
To use or create a component that is likely to be used somewhere
else, refer to `vue_shared/components`.

A good guideline to know when you should create a component is to think if
it could be reusable elsewhere.

For example, tables are used in a quite amount of places across GitLab, a table
would be a good fit for a component. On the other hand, a table cell used only
in one table would not be a good use of this pattern.

You can read more about components in Vue.js site, [Component System](https://v2.vuejs.org/v2/guide/#Composing-with-Components).

### Pinia

[Learn more about Pinia in GitLab](pinia.md).

### Vuex

[Vuex is deprecated](vuex.md#deprecated), consider [migrating](migrating_from_vuex.md).

### Vue Router

To add [Vue Router](https://router.vuejs.org/) to a page:

1. Add a catch-all route to the Rails route file using a wildcard named `*vueroute`:

   ```ruby
   # example from ee/config/routes/project.rb

   resources :iteration_cadences, path: 'cadences(/*vueroute)', action: :index
   ```

   The above example serves the `index` page from `iteration_cadences` controller to any route
   matching the start of the `path`, for example `groupname/projectname/-/cadences/123/456/`.
1. Pass the base route (everything before `*vueroute`) to the frontend to use as the `base` parameter to initialize Vue Router:

   ```haml
   .js-my-app{ data: { base_path: project_iteration_cadences_path(project) } }
   ```

1. Initialize the router:

   ```javascript
   Vue.use(VueRouter);

   export function createRouter(basePath) {
     return new VueRouter({
       routes: createRoutes(),
       mode: 'history',
       base: basePath,
     });
   }
   ```

1. Add a fallback for unrecognised routes with `path: '*'`. Either:
   - Add a redirect to the end of your routes array:

     ```javascript
     const routes = [
       {
         path: '/',
         name: 'list-page',
         component: ListPage,
       },
       {
         path: '*',
         redirect: '/',
       },
     ];
     ```

   - Add a fallback component to the end of your routes array:

     ```javascript
     const routes = [
       {
         path: '/',
         name: 'list-page',
         component: ListPage,
       },
       {
         path: '*',
         component: NotFound,
       },
     ];
     ```

1. Optional. To also allow using the path helper for child routes, add `controller` and `action`
   parameters to use the parent controller.

   ```ruby
   resources :iteration_cadences, path: 'cadences(/*vueroute)', action: :index do
     resources :iterations, only: [:index, :new, :edit, :show], constraints: { id: /\d+/ }, controller: :iteration_cadences, action: :index
   end
   ```

   This means routes like `/cadences/123/iterations/456/edit` can be validated on the backend,
   for example to check group or project membership.
   It also means we can use the `_path` helper, which means we can load the page in feature specs
   without manually building the `*vueroute` part of the path..

### Mixing Vue and jQuery

- Mixing Vue and jQuery is not recommended.
- To use a specific jQuery plugin in Vue, [create a wrapper around it](https://vuejs.org/v2/examples/select2.html).
- It is acceptable for Vue to listen to existing jQuery events using jQuery event listeners.
- It is not recommended to add new jQuery events for Vue to interact with jQuery.

### Mixing Vue and JavaScript classes (in the data function)

In the [Vue documentation](https://v2.vuejs.org/v2/api/#Options-Data) the Data function/object is defined as follows:

> The data object for the Vue instance. Vue recursively converts its properties into getter/setters
to make it "reactive". The object must be plain: native objects such as browser API objects and
prototype properties are ignored. A guideline is that data should just be data - it is not
recommended to observe objects with their own stateful behavior.

Based on the Vue guidance:

- **Do not** use or create a JavaScript class in your [data function](https://v2.vuejs.org/v2/api/#data).
- **Do not** add new JavaScript class implementations.
- **Do** encapsulate complex state management with cohesive decoupled components or [a state manager](state_management.md).
- **Do** maintain existing implementations using such approaches.
- **Do** Migrate components to a pure object model when there are substantial changes to it.
- **Do** move business logic to separate files, so you can test them separately from your component.

#### Why

Additional reasons why having a JavaScript class presents maintainability issues on a huge codebase:

- After a class is created, it can be extended in a way that can infringe Vue reactivity and best practices.
- A class adds a layer of abstraction, which makes the component API and its inner workings less clear.
- It makes it harder to test. Because the class is instantiated by the component data function, it is
  harder to 'manage' component and class separately.
- Adding Object Oriented Principles (OOP) to a functional codebase adds another way of writing code, reducing consistency and clarity.

## Style guide

Refer to the Vue section of our [style guide](style/vue.md)
for best practices while writing and testing your Vue components and templates.

## Composition API

With Vue 2.7 it is possible to use [Composition API](https://vuejs.org/guide/introduction.html#api-styles) in Vue components and as standalone composables.

### Prefer `<script>` over `<script setup>`

Composition API allows you to place the logic in the `<script>` section of the component or to have a dedicated `<script setup>` section. We should use `<script>` and add Composition API to components using `setup()` property:

```html
<script>
  import { computed } from 'vue';

  export default {
    name: 'MyComponent',
    setup(props) {
      const doubleCount = computed(() => props.count*2)
    }
  }
</script>
```

### `v-bind` limitations

Avoid using `v-bind="$attrs"` unless absolutely necessary. You might need this when
developing a native control wrapper. (This is a good candidate for a `gitlab-ui` component.)
In any other cases, always prefer using `props` and explicit data flow.

Using `v-bind="$attrs"` leads to:

1. A loss in component's contract. The `props` were designed specifically
   to address this problem.
1. High maintenance cost for each component in the tree. `v-bind="$attrs"` is specifically
   hard to debug because you must scan the whole hierarchy of components to understand
   the data flow.
1. Problems during migration to Vue 3. `$attrs` in Vue 3 include event listeners which
   could cause unexpected side-effects after Vue 3 migration is completed.

### Aim to have one API style per component

When adding `setup()` property to Vue component, consider refactoring it to Composition API entirely. It's not always feasible, especially for large components, but we should aim to have one API style per component for readability and maintainability.

### Composables

With Composition API, we have a new way of abstracting logic including reactive state to _composables_. Composable is the function that can accept parameters and return reactive properties and methods to be used in Vue component.

```javascript
// useCount.js
import { ref } from 'vue';

export function useCount(initialValue) {
  const count = ref(initialValue)

  function incrementCount() {
    count.value += 1
  }

  function decrementCount() {
    count.value -= 1
  }

  return { count, incrementCount, decrementCount }
}
```

```javascript
// MyComponent.vue
import { useCount } from 'useCount'

export default {
  name: 'MyComponent',
  setup() {
    const { count, incrementCount, decrementCount } = useCount(5)

    return { count, incrementCount, decrementCount }
  }
}
```

#### Prefix function and filenames with `use`

Common naming convention in Vue for composables is to prefix them with `use` and then refer to composable functionality briefly (`useBreakpoints`, `useGeolocation` etc). The same rule applies to the `.js` files containing composables - they should start with `use_` even if the file contains more than one composable.

#### Avoid lifecycle pitfalls

When building a composable, we should aim to keep it as simple as possible. Lifecycle hooks add complexity to composables and might lead to unexpected side effects. To avoid that we should follow these principles:

- Minimize lifecycle hooks usage whenever possible, prefer accepting/returning callbacks instead.
- If your composable needs lifecycle hooks, make sure it also performs a cleanup. If we add a listener on `onMounted`, we should remove it on `onUnmounted` within the same composable.
- Always set up lifecycle hooks immediately:

```javascript
// bad
const useAsyncLogic = () => {
  const action = async () => {
    await doSomething();
    onMounted(doSomethingElse);
  };
  return { action };
};

// OK
const useAsyncLogic = () => {
  const done = ref(false);
  onMounted(() => {
    watch(
      done,
      () => done.value && doSomethingElse(),
      { immediate: true },
    );
  });
  const action = async () => {
    await doSomething();
    done.value = true;
  };
  return { action };
};
```

#### Avoid escape hatches

It might be tempting to write a composable that does everything as a black box, using some of the escape hatches that Vue provides. But for most of the cases this makes them too complex and hard to maintain. One escape hatch is the `getCurrentInstance` method. This method returns an instance of a current rendering component. Instead of using that method, you should prefer passing down the data or methods to a composable via arguments.

```javascript
const useSomeLogic = () => {
  doSomeLogic();
  getCurrentInstance().emit('done'); // bad
};
```

```javascript
const done = () => emit('done');

const useSomeLogic = (done) => {
  doSomeLogic();
  done(); // good, composable doesn't try to be too smart
}
```

#### Testing composables

<!-- TBD -->

## Testing Vue Components

Refer to the [Vue testing style guide](style/vue.md#vue-testing)
for guidelines and best practices for testing your Vue components.

Each Vue component has a unique output. This output is always present in the render function.

Although each method of a Vue component can be tested individually, our goal is to test the output
of the render function, which represents the state at all times.

Visit the [Vue testing guide](https://v2.vuejs.org/v2/guide/testing.html#Unit-Testing) for help.

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
    // IMPORTANT: Clean up the axios mock adapter
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

We should test for events emitted in response to an action in our component. This testing
verifies the correct events are being fired with the correct arguments.

For any native DOM events we should use [`trigger`](https://v1.test-utils.vuejs.org/api/wrapper/#trigger)
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

When firing a Vue event, use [`emit`](https://v2.vuejs.org/v2/guide/components-custom-events.html).

```javascript
wrapper = shallowMount(DropdownItem);

...

it('should fire the itemClicked event', () => {
  DropdownItem.vm.$emit('itemClicked');
  ...
})
```

We should verify an event has been fired by asserting against the result of the
[`emitted()`](https://v1.test-utils.vuejs.org/api/wrapper/#emitted) method.

It is a good practice to prefer to use `vm.$emit` over `trigger` when emitting events from child components.

Using `trigger` on the component means we treat it as a white box: we assume that the root element of child component has a native `click` event. Also, some tests fail in Vue3 mode when using `trigger` on child components.

   ```javascript
   const findButton = () => wrapper.findComponent(GlButton);

   // bad
   findButton().trigger('click');

   // good
   findButton().vm.$emit('click');
   ```

## Vue.js Expert Role

You should only apply to be a Vue.js expert when your own merge requests and your reviews show:

- Deep understanding of Vue reactivity
- Vue and [Pinia](pinia.md) code are structured according to both official and our guidelines
- Full understanding of testing Vue components and Pinia stores
- Knowledge about the existing Vue and Pinia applications and existing reusable components

## Vue 2 -> Vue 3 Migration

> - This section is added temporarily to support the efforts to migrate the codebase from Vue 2.x to Vue 3.x

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
      >{{ todo.text }}</div>
      <footer class="gl-border-t-1 gl-mt-3 gl-pt-3">
        <gl-form-input
          type="text"
          v-model="todoText"
          data-testid="text-input"
        >
        <gl-button
          variant="confirm"
          data-testid="add-button"
          @click="addTodo"
        >Add</gl-button>
      </footer>
    </template>
  </div>
</template>
```
