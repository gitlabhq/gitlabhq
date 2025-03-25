---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Vue.js style guide
---

## Linting

We default to [eslint-vue-plugin](https://github.com/vuejs/eslint-plugin-vue), with the `plugin:vue/recommended`.
Check the [rules](https://github.com/vuejs/eslint-plugin-vue#bulb-rules) for more documentation.

## Basic Rules

1. Use `.vue` for Vue templates. Do not use `%template` in HAML.
1. Explicitly define data being passed into the Vue app

   ```javascript
   // bad
   return new Vue({
     el: '#element',
     name: 'ComponentNameRoot',
     components: {
       componentName
     },
     provide: {
       ...someDataset
     },
     props: {
       ...anotherDataset
     },
     render: createElement => createElement('component-name'),
   }));

   // good
   const { foobar, barfoo } = someDataset;
   const { foo, bar } = anotherDataset;

   return new Vue({
     el: '#element',
     name: 'ComponentNameRoot',
     components: {
       componentName
     },
     provide: {
       foobar,
       barfoo
     },
     props: {
       foo,
       bar
     },
     render: createElement => createElement('component-name'),
   }));
   ```

   We discourage the use of the spread operator in this specific case in
   order to keep our codebase explicit, discoverable, and searchable.
   This applies in any place where we would benefit from the above, such as
   when [initializing Vuex state](../vuex.md#why-not-just-spread-the-initial-state).
   The pattern above also enables us to easily parse non scalar values during
   instantiation.

   ```javascript
   return new Vue({
     el: '#element',
     name: 'ComponentNameRoot',
     components: {
       componentName
     },
     props: {
       foo,
       bar: parseBoolean(bar)
     },
     render: createElement => createElement('component-name'),
   }));
   ```

## Component usage within templates

1. Prefer a component's kebab-cased name over other styles when using it in a template

   ```html
   // bad
   <MyComponent />

   // good
   <my-component />
   ```

## `<style>` tags

We don't use `<style>` tags in Vue components for a few reasons:

1. You cannot use SCSS variables and mixins or [Tailwind CSS](scss.md#tailwind-css) `@apply` directive.
1. These styles get inserted at runtime.
1. We already have a few other ways to define CSS.

Instead of using a `<style>` tag you should use [Tailwind CSS utility classes](scss.md#tailwind-css) or [page specific CSS](https://gitlab.com/groups/gitlab-org/-/epics/3694).

## Vue testing

Over time, a number of programming patterns and style preferences have emerged in our efforts to
effectively test Vue components. The following guide describes some of these.
**These are not strict guidelines**, but rather a collection of suggestions and good practices that
aim to provide insight into how we write Vue tests at GitLab.

### Mounting a component

Typically, when testing a Vue component, the component should be "re-mounted" in every test block.

To achieve this:

1. Create a mutable `wrapper` variable inside the top-level `describe` block.
1. Mount the component using [`mount`](https://v1.test-utils.vuejs.org/api/#mount) or [`shallowMount`](https://v1.test-utils.vuejs.org/api/#shallowMount).
1. Reassign the resulting [`Wrapper`](https://v1.test-utils.vuejs.org/api/wrapper/#wrapper) instance to our `wrapper` variable.

Creating a global, mutable wrapper provides a number of advantages, including the ability to:

- Define common functions for finding components/DOM elements:

  ```javascript
  import MyComponent from '~/path/to/my_component.vue';
  describe('MyComponent', () => {
    let wrapper;

    // this can now be reused across tests
    const findMyComponent = wrapper.findComponent(MyComponent);
    // ...
  })
  ```

- Use a `beforeEach` block to mount the component (see
  [the `createComponent` factory](#the-createcomponent-factory) for more information).
- Automatically destroy the component after the test is run with [`enableAutoDestroy`](https://v1.test-utils.vuejs.org/api/#enableautodestroy-hook)
  set in [`shared_test_setup.js`](https://gitlab.com/gitlab-org/gitlab/-/blob/d0bdc8370ef17891fd718a4578e41fef97cf065d/spec/frontend/__helpers__/shared_test_setup.js#L20).

#### Async child components

`shallowMount` will not create component stubs for [async child components](https://v2.vuejs.org/v2/guide/components-dynamic-async#Async-Components). In order to properly stub async child components, use the [`stubs`](https://v1.test-utils.vuejs.org/api/options.html#stubs) option. Make sure the async child component has a [`name`](https://v2.vuejs.org/v2/api/#name) option defined, otherwise your `wrapper`'s `findComponent` method may not work correctly.

#### The `createComponent` factory

To avoid duplicating our mounting logic, it's useful to define a `createComponent` factory function
that we can reuse in each test block. This is a closure which should reassign our `wrapper` variable
to the result of [`mount`](https://v1.test-utils.vuejs.org/api/#mount) and
[`shallowMount`](https://v1.test-utils.vuejs.org/api/#shallowMount):

```javascript
import MyComponent from '~/path/to/my_component.vue';
import { shallowMount } from '@vue/test-utils';

describe('MyComponent', () => {
  // Initiate the "global" wrapper variable. This will be used throughout our test:
  let wrapper;

  // Define our `createComponent` factory:
  function createComponent() {
    // Mount component and reassign `wrapper`:
    wrapper = shallowMount(MyComponent);
  }

  it('mounts', () => {
    createComponent();

    expect(wrapper.exists()).toBe(true);
  });

  it('`isLoading` prop defaults to `false`', () => {
    createComponent();

    expect(wrapper.props('isLoading')).toBe(false);
  });
})
```

Similarly, we could further de-duplicate our test by calling `createComponent` in a `beforeEach` block:

```javascript
import MyComponent from '~/path/to/my_component.vue';
import { shallowMount } from '@vue/test-utils';

describe('MyComponent', () => {
  // Initiate the "global" wrapper variable. This will be used throughout our test
  let wrapper;

  // define our `createComponent` factory
  function createComponent() {
    // mount component and reassign `wrapper`
    wrapper = shallowMount(MyComponent);
  }

  beforeEach(() => {
    createComponent();
  });

  it('mounts', () => {
    expect(wrapper.exists()).toBe(true);
  });

  it('`isLoading` prop defaults to `false`', () => {
    expect(wrapper.props('isLoading')).toBe(false);
  });
})
```

#### `createComponent` best practices

1. Consider using a single (or a limited number of) object arguments over many arguments.
   Defining single parameters for common data like `props` is okay,
   but keep in mind our [JavaScript style guide](javascript.md#limit-number-of-parameters) and
   stay within the parameter number limit:

   ```javascript
   // bad
   function createComponent(props, stubs, mountFn, foo) { }

   // good
   function createComponent({ props, stubs, mountFn, foo } = {}) { }

   // good
   function createComponent(props = {}, { stubs, mountFn, foo } = {}) { }
   ```

1. If you require both `mount` _and_ `shallowMount` within the same set of tests, it
   can be useful define a `mountFn` parameter for the `createComponent` factory that accepts
   the mounting function (`mount` or `shallowMount`) to be used to mount the component:

   ```javascript
   import { shallowMount } from '@vue/test-utils';

   function createComponent({ mountFn = shallowMount } = {}) { }
   ```

1. Use the `mountExtended` and `shallowMountExtended` helpers to expose `wrapper.findByTestId()`:

   ```javascript
   import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
   import { SomeComponent } from 'components/some_component.vue';

   let wrapper;

   const createWrapper = () => { wrapper = shallowMountExtended(SomeComponent); };
   const someButton = () => wrapper.findByTestId('someButtonTestId');
   ```

1. Avoid using `data`, `methods`, or any other mounting option that extends component internals.

   ```javascript
   import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
   import { SomeComponent } from 'components/some_component.vue';

   let wrapper;

   // bad :( - This circumvents the actual user interaction and couples the test to component internals.
   const createWrapper = ({ data }) => {
     wrapper = shallowMountExtended(SomeComponent, {
       data
     });
   };

   // good :) - Helpers like `clickShowButton` interact with the actual I/O of the component.
   const createWrapper = () => {
     wrapper = shallowMountExtended(SomeComponent);
   };
   const clickShowButton = () => {
     wrapper.findByTestId('show').trigger('click');
   }
   ```

### Setting component state

1. Avoid using [`setProps`](https://v1.test-utils.vuejs.org/api/wrapper/#setprops) to set
   component state wherever possible. Instead, set the component's
   [`propsData`](https://v1.test-utils.vuejs.org/api/options.html#propsdata) when mounting the component:

   ```javascript
   // bad
   wrapper = shallowMount(MyComponent);
   wrapper.setProps({
     myProp: 'my cool prop'
   });

   // good
   wrapper = shallowMount({ propsData: { myProp: 'my cool prop' } });
   ```

   The exception here is when you wish to test component reactivity in some way.
   For example, you may want to test the output of a component when after a particular watcher has
   executed. Using `setProps` to test such behavior is okay.

1. Avoid using [`setData`](https://v1.test-utils.vuejs.org/api/wrapper/#setdata) which sets the
   component's internal state and circumvents testing the actual I/O of the component.
   Instead, trigger events on the component's children or other side-effects to force state changes.

### Accessing component state

1. When accessing props or attributes, prefer the `wrapper.props('myProp')` syntax over
   `wrapper.props().myProp` or `wrapper.vm.myProp`:

   ```javascript
   // good
   expect(wrapper.props().myProp).toBe(true);
   expect(wrapper.attributes().myAttr).toBe(true);

   // better
   expect(wrapper.props('myProp').toBe(true);
   expect(wrapper.attributes('myAttr')).toBe(true);
   ```

1. When asserting multiple props, check the deep equality of the `props()` object with
   [`toEqual`](https://jestjs.io/docs/expect#toequalvalue):

   ```javascript
   // good
   expect(wrapper.props('propA')).toBe('valueA');
   expect(wrapper.props('propB')).toBe('valueB');
   expect(wrapper.props('propC')).toBe('valueC');

   // better
   expect(wrapper.props()).toEqual({
     propA: 'valueA',
     propB: 'valueB',
     propC: 'valueC',
   });
   ```

1. If you are only interested in some of the props, you can use
   [`toMatchObject`](https://jestjs.io/docs/expect#tomatchobjectobject). Prefer `toMatchObject`
   over [`expect.objectContaining`](https://jestjs.io/docs/expect#expectobjectcontainingobject):

   ```javascript
   // good
   expect(wrapper.props()).toEqual(expect.objectContaining({
     propA: 'valueA',
     propB: 'valueB',
   }));

   // better
   expect(wrapper.props()).toMatchObject({
     propA: 'valueA',
     propB: 'valueB',
   });
   ```

### Testing props validation

When checking component props use `assertProps` helper. Props validation failures will be thrown as errors:

```javascript
import { assertProps } from 'helpers/assert_props'

// ...

expect(() => assertProps(SomeComponent, { invalidPropValue: '1', someOtherProp: 2 })).toThrow()
```
