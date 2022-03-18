---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Migration to Vue 3

The migration from Vue 2 to 3 is tracked in epic [&6252](https://gitlab.com/groups/gitlab-org/-/epics/6252).

To ease migration to Vue 3.x, we have added [eslint rules](https://gitlab.com/gitlab-org/frontend/eslint-plugin/-/merge_requests/50)
that prevent us from using the following deprecated features in the codebase.

## Vue filters

**Why?**

Filters [are removed](https://github.com/vuejs/rfcs/blob/master/active-rfcs/0015-remove-filters.md) from the Vue 3 API completely.

**What to use instead**

Component's computed properties / methods or external helpers.

## Event hub

**Why?**

`$on`, `$once`, and `$off` methods [are removed](https://github.com/vuejs/rfcs/blob/master/active-rfcs/0020-events-api-change.md) from the Vue instance, so in Vue 3 it can't be used to create an event hub.

**When to use**

If you are in a Vue app that doesn't use any event hub, try to avoid adding a new one unless absolutely necessary. For example, if you need a child component to react to its parent's event, it's preferred to pass a prop down. Then, use the watch property on that prop in the child component to create the desired side effect.

If you need cross-component communication (between different Vue apps), then perhaps introducing a hub is the right decision.

**What to use instead**

We have created a factory that you can use to instantiate a new [mitt](https://github.com/developit/mitt)-like event hub.

This makes it easier to migrate existing event hubs to the new recommended approach, or
to create new ones.

```javascript
import createEventHub from '~/helpers/event_hub_factory';

export default createEventHub();
```

Event hubs created with the factory expose the same methods as Vue 2 event hubs (`$on`, `$once`, `$off` and
`$emit`), making them backward compatible with our previous approach.

## \<template functional>

**Why?**

In Vue 3, `{ functional: true }` option [is removed](https://github.com/vuejs/rfcs/blob/functional-async-api-change/active-rfcs/0007-functional-async-api-change.md) and `<template functional>` is no longer supported.

**What to use instead**

Functional components must be written as plain functions:

```javascript
import { h } from 'vue'

const FunctionalComp = (props, slots) => {
  return h('div', `Hello! ${props.name}`)
}
```

It is not recommended to replace stateful components with functional components unless you absolutely need a performance improvement right now. In Vue 3, performance gains for functional components are negligible.

## Old slots syntax with `slot` attribute

**Why?**

In Vue 2.6 `slot` attribute was already deprecated in favor of `v-slot` directive. The `slot` attribute usage is still allowed and sometimes we prefer using it because it simplifies unit tests (with old syntax, slots are rendered on `shallowMount`). However, in Vue 3 we can't use old syntax anymore.

**What to use instead**

The syntax with `v-slot` directive. To fix rendering slots in `shallowMount`, we need to stub a child component with slots explicitly.

```html
<!-- MyAwesomeComponent.vue -->
<script>
import SomeChildComponent from './some_child_component.vue'

export default {
  components: {
    SomeChildComponent
  }
}

</script>

<template>
  <div>
    <h1>Hello GitLab!</h1>
    <some-child-component>
      <template #header>
        Header content
      </template>
    </some-child-component>
  </div>
</template>
```

```javascript
// MyAwesomeComponent.spec.js

import SomeChildComponent from '~/some_child_component.vue'

shallowMount(MyAwesomeComponent, {
  stubs: {
    SomeChildComponent
  }
})
```

## Props default function `this` access

**Why?**

In Vue 3, props default value factory functions no longer have access to `this`
(the component instance).

**What to use instead**

Write a computed prop that resolves the desired value from other props. This
will work in both Vue 2 and 3.

```html
<script>
export default {
  props: {
    metric: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    actualTitle() {
      return this.title ?? this.metric;
    },
  },
}

</script>

<template>
  <div>{{ actualTitle }}</div>
</template>
```

[In Vue 3](https://v3.vuejs.org/guide/migration/props-default-this.html#props-default-function-this-access),
the props default value factory is passed the raw props as an argument, and can
also access injections.
