---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Vue 3 Testing
---

As we transition to using Vue 3, it's important that our tests pass in Vue 3 mode.
We're adding progressively stricter checks to our pipelines to enforce proper Vue 3 testing.

Right now, we fail pipelines if:

1. A new test file is added that fails in Vue 3 mode.
1. An existing test file fails under Vue 3 that was previously passing.
1. One of the known failures on the [quarantine list](#quarantine-list) is now passing and has not been removed from the quarantine list.

## Running unit tests using Vue 3

To run unit tests using Vue 3, set the `VUE_VERSION` environment variable to `3` when executing jest.

```shell
VUE_VERSION=3 yarn jest #[file-path]
```

## Testing Caveats

### Ref management when mocking composables

A common pattern when testing Vue 3 composables is to mock the `ref` or `computed` values that these files return.

Consider the following demo composable:

```javascript
export const useCounter = () => {
  const counter = ref(1)
  const increase = () => { counter.value += 1 }

  return { counter, increase }
}
```

If we have a component that is currently using this composable and exposing the counter, we will want to write a test to cover the functionality. In _some_ cases such as with this simple example we can get away with not mocking the composable at all, but with more complicated features such as Tanstack Query wrappers or Apollo wrappers leveraging `jest.mock` may be necessary.

In such cases the test file will require mocking the composable:

```html
<script setup>
const { counter, increase } = useCounter()
</script>

<template>
  <p>Super useful counter: {{ counter }}</p>
  <button @click="increase">+</button>
</template>
```

```javascript
import { ref } from 'vue'
import { useCounter } from '~/composables/useCounter'

jest.mock('~/composables/useCounter')

describe('MyComponent', () => {
  const increaseMock = jest.fn()
  const counter = ref(1)

  beforeEach(() => {
    useCounter.mockReturnValue({
      increase: increaseMock,
      counter
    })
  })

  describe('When the counter is 2', () => {
    beforeEach(() => {
      counter.value = 2
      createComponent()
    })

    it('...', () => {})
  })

  it('should default to 1', () => {
    createComponent()

    expect(findSuperUsefulCounter().text()).toBe(1)
    // failure
  })
})
```

Note in the above example that we are creating both a mock of the function that is returned by the composable and the `counter` ref - however a very important step is missing the example.

The `counter` constant is a `ref`, which means that on every test when we modify it the value we assign to it will be retained. In the example the second `it` block will fail as the `counter` will retain the value assigned in some of our previous tests.

The solution and best practice is to _always_ reset your `ref`s on the top most level `beforeEach` block.

```javascript
import { ref } from 'vue'
import { useCounter } from '~/composables/useCounter'

jest.mock('~/composables/useCounter')

describe('MyComponent', () => {
  const increaseMock = jest.fn()

  // We can initialize to `undefined` to be extra careful
  const counter = ref(undefined)

  beforeEach(() => {
    counter.value = 1
    useCounter.mockReturnValue({
      increase: increaseMock,
      counter
    })
  })

  describe('When the counter is 2', () => {
    beforeEach(() => {
      counter.value = 2
      createComponent()
    })

    it('...', () => {})
  })

  it('should default to 1', () => {
    createComponent()

    expect(findSuperUsefulCounter().text()).toBe(1)
    // pass
  })
})
```

### Vue router

If you are testing a Vue Router configuration using a real (not mocked) `VueRouter` object, read the following
[guidelines](https://test-utils.vuejs.org/guide/advanced/vue-router.html#Using-a-Real-Router). A
source of failure is that Vue Router 4 handles routing asynchronously, therefore we should
`await` for the routing operations to be completed. You can use the `waitForPromises` utility to
wait until all promises are flushed.

In the following example, a test asserts that VueRouter navigated to a page after clicking a button. If
`waitForPromises` is not invoked after clicking the button, the assertion would fail because the router's
state hasn't transitioned to the target page.

```javascript
it('navigates to /create when clicking New workspace button', async () => {
  expect(findWorkspacesListPage().exists()).toBe(true);

  await findNewWorkspaceButton().trigger('click');
  await waitForPromises();

  expect(findCreateWorkspacePage().exists()).toBe(true);
});
```

### Vue Apollo troubleshooting

You might encounter some unit test failures on components that execute Apollo mutations and
update the in-memory query cache, for example:

```shell
ApolloError: 'get' on proxy: property '[property]' is a read-only and non-configurable data property on the proxy target but the proxy did not return its actual value (expected '#<Object>' but got '#<Object>')
```

This error happens because Apollo tries to modify a [Vue reactive object](https://vuejs.org/guide/essentials/reactivity-fundamentals.html)
when we call the `writeQuery` or `updateQuery` methods. Avoid using objects passed through a component's
property in operations that update Apollo's cache. You should always rely on constructing new objects or
data that already exists in the Apollo's cache. As a last resort, use the `cloneDeep` utility to remove
the Vue's reactivity proxy from the target object.

In the following example, the component updates the Apollo's in-memory cache after the mutation succeeds
by swapping the `agent` object between two arrays. The `agent` object is also available in the `agent`
property, but it is reactive object. The incorrect approach references the `agent` object passed to
the component as a property which causes the proxy error. The correct approach finds the `agent`
object that is already stored in the Apollo's cache.

```html
<script>
import { toRaw } from 'vue';

export default {
  props: {
    namespace: {
      type: String,
      required: true,
    },
    agent: {
      type: Object,
      required: true,
    },
  },

  methods: {
    async execute() {
      try {
        await this.$apollo.mutate({
          mutation: createClusterAgentMappingMutation,
          update(store) {
            store.updateQuery(
              {
                query: getAgentsWithAuthorizationStatusQuery,
                variables: { namespace },
              },
              (sourceData) =>
                produce(sourceData, (draftData) => {
                  const { mappedAgents, unmappedAgents } = draftData.namespace;

                  /*
                  * BAD: The error described in this section is caused by adding a Vue reactive
                  * object the nodes array. `this.agent` is a component property hence it is wrapped
                  * with a reactivity proxy.
                  */
                  mappedAgents.nodes.push(this.agent);
                  unmappedAgents.nodes = removeFrom.nodes.filter((node) => node.id !== agent.id);

                  /*
                  * PREFERRED FIX: Only use data that already exists in the in-memory cache.
                  */
                  const targetAgentIndex = removeFrom.nodes.findIndex((node) => node.id === agent.id);

                  mappedAgents.nodes.push(removeFrom.nodes[targetAgentIndex]);
                  unmappedAgents.nodes.splice(targetAgentIndex, 1);


                  /*
                  * ALTERNATIVE (LAST RESORT) FIX: Use lodash `cloneDeep` to create a clone
                  * of the object without Vue reactivity:
                  */
                  mappedAgents.nodes.push(cloneDeep(this.agent));
                  unmappedAgents.nodes = removeFrom.nodes.filter((node) => node.id !== agent.id);

                }),
            );
          },
        });
      } catch (e) {
        Sentry.captureException(e);
        this.$emit('error', e);
      }
    },
  },
};
</script>

```

### Testing Vue router

When testing a full non-mocked `vue-router@4` there are a few caveats to keep in consideration for compatibility with Vue 2.

#### Window location

`vue-router@4` will not detect changes in window location, so setting a current URL with helpers such as `setWindowLocation` will not have an effect.

Instead, set an initial route or navigate to another route manually.

#### Initial route

When setting an initial route for your tests, `vue-router@4` will default to a `/` route. If the router configuration doesn't define a route for `/` path the test will error out by default. In this case, it is important to navigate to one of the defined routes before a component is created.

```javascript
router = createRouter();

await router.push({ name: 'tab', params: { tabId }})
```

Note the `await` is necessary, since [all navigations are always asynchronous](https://router.vuejs.org/guide/migration/#All-navigations-are-now-always-asynchronous).

#### Navigating to another route

To navigate to another route on an already mounted component, it is necessary to `await` calls to `push` or `replace` on the router.

```javascript
createComponent()

await router.push('/different-route')
```

When access to the `push` method is not available, for example in cases where we are triggering a `push` _inside the component's code_ through an event, `await waitForPromises` will be sufficient.

Consider the following component:

```html
<script>
export default {
  methods: {
    nextPage() {
      this.$router.push({
        path: 'some path'
      })
    }
  }
}
</script>
<template>
  <gl-keyset-pagination @push="nextPage" />
</template>
```

If we want to be able to test that the `$router.push` call is made, we must trigger the navigation through the `next` even on the `gl-keyset-pagination` component.

```javascript
wrapper.findComponent(GlKeysetNavigation).vm.$emit('push');
// $router.push is triggered in the component
await waitForPromises()
```

#### Debugging

More often than not you will find yourself running into cryptic errors like the one below.

```shell
Unexpected calls to console (1) with:

        [1] warn: [Vue Router warn]: uncaught error during route navigation:

      23 |     .join('\n');
      24 |
    > 25 |   throw new Error(
         |         ^
      26 |     `Unexpected calls to console (${consoleCalls.length}) with:\n${consoleCallsList}\n`,
      27 |   );
      28 | };
```

In order to better understand what Vue router needs, use `jest.fn()` to override `console.warn` so you can see the output of the error.

```javascript
console.warn = jest.fn()

afterEach(() => {
  console.log(console.warn.mock.calls)
})
```

This will turn the above into a digestible error. Don't forget to remove this code before you submit your MR.

```shell
'[Vue Router warn]: Record with path "/" is either missing a "component(s)" or "children" property.'
```

#### Component and Children property

Unlike Vue router 3 (Vue 2), Vue router 4 requires a `component` or `children` property (with their respective `component`) to be defined. In some scenarios we have historically used Vue router to manage router query variables without a `router-view`, for example in `app/assets/javascripts/projects/your_work/components/app.vue`.

This is an anti-pattern, as Vue router is overkill, a preferable approach would be to use vanilla JS to manage query routes with [URL searchParams](https://developer.mozilla.org/en-US/docs/Web/API/URL/searchParams) for example.

When rewriting the component is not possible, passing the `App` component that the application is rendering without the use of `router-view` will let the tests pass, however, this opens up the possibility of introducing unwanted behavior in the future if a `<router-view />` is added to the component and should be used with care.

## Quarantine list

The `scripts/frontend/quarantined_vue3_specs.txt` file is built up of all the known failing Vue 3 test files.
In order to not overwhelm us with failing pipelines, these files are skipped on the Vue 3 test job.

If you're reading this, it's likely you were sent here by a failing quarantine job.
This job is confusing as it fails when a test passes and it passes if they all fail.
The reason for this is because all newly passing tests should be [removed from the quarantine list](#removing-from-the-quarantine-list).
Congratulate yourself on fixing a previously failing test and remove it from the quarantine list to get this pipeline passing again.

### Removing from the quarantine list

If your pipeline is failing because of the `vue3 check quarantined` jobs, good news!
You fixed a previously failing test!
What you need to do now is remove the newly-passing test from the quarantine list.
This ensures that the test will continue to pass and prevent any further regressions.

### Adding to the quarantine list

Don't do it.
This list should only get smaller, not larger.
If your MR introduces a new test file or breaks a currently passing one, then you should fix it.

If you are moving a test file from one location to another, then it's okay to modify the location in the quarantine list.
However, before doing so, consider fixing the test first.
