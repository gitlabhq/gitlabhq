---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Vue 3 Testing

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
