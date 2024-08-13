---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Vue 3 Testing

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
