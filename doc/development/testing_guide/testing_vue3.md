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

### Vue Apollo troubleshooting

You might encounter some unit test failures on components that execute Apollo mutations and
update the in-memory query cache, for example:

```shell
ApolloError: 'get' on proxy: property '[property]' is a read-only and non-configurable data property on the proxy target but the proxy did not return its actual value (expected '#<Object>' but got '#<Object>')
```

This error happens because Apollo tries to access or modify
a [Vue reactive object](https://vuejs.org/guide/essentials/reactivity-fundamentals.html) when we call the
`writeQuery` or `updateQuery` methods. As a general rule, never use a component's property in operations
that update Apollo's cache. If you must, use the `toRaw` utility to remove the Vue's reactivity proxy from
the target object.

The following example comes from a real-life scenario where this failure happened and provides two alternatives
to fix the test failure:

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
                  * PREFERRED FIX: Use `toRaw` to remove the reactivity proxy.
                  */
                  mappedAgents.nodes.push(toRaw(this.agent));
                  unmappedAgents.nodes = removeFrom.nodes.filter((node) => node.id !== agent.id);

                  /*
                  * ALTERNATIVE FIX: Only use data that already exists in the in-memory cache.
                  */
                  const targetAgentIndex = removeFrom.nodes.findIndex((node) => node.id === agent.id);

                  mappedAgents.nodes.push(removeFrom.nodes[targetAgentIndex]);
                  unmappedAgents.nodes.splice(targetAgentIndex, 1);
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
