---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Migration to Vue 3
---

The migration from Vue 2 to 3 is tracked in epic [&6252](https://gitlab.com/groups/gitlab-org/-/epics/6252).

To ease migration to Vue 3.x, we have added [ESLint rules](https://gitlab.com/gitlab-org/frontend/eslint-plugin/-/merge_requests/50)
that prevent us from using the following deprecated features in the codebase.

## GitLab can use Vue 3 (@vue/compat)

The GitLab frontend team has enabled Vue 3 (@vue/compat) for development environments like GDK. While not yet production-ready, you can opt-in locally to verify your client code is forward-compatible with Vue 3.

**How does it work?** When the build tool (Vite or Webpack) detects the VUE_VERSION=3 environment variable,
it uses module aliasing to swap out certain dependencies, including Vue itself, for their Vue 3-compatible counterparts.

Some of these replacement libraries are maintained by the team and act as thin wrappers around existing
libraries, making them Vue 3-compatible without requiring any changes in consumer code.

## Setup GDK to use Vue 3 (@vue/compat)

This guide walks you through configuring the GitLab Development Kit (GDK) to use Vite as the build tool with Vue 3.

### Prerequisites

- GDK installed and configured
- Basic familiarity with Vue.js and Vite
- Vite configured in your GDK environment (see [GDK Vite Settings](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/configuration.md?ref_type=heads#vite-settings))

### Initial Setup

### Switching Between Vue Versions

To switch between Vue 2 and Vue 3, follow these steps:

1. **Set the desired Vue version:**

   ```shell
   gdk config set vite.vue_version 3  # or 2
   ```

1. **Reconfigure GDK:**

   ```shell
   gdk reconfigure
   ```

1. **Restart GDK:**

   ```shell
   gdk restart # or `gdk start` if running for the first time
   ```

> **Important:** You can clear caches with `yarn clean` or `gdk kill vite` if you face issues switching Vue versions.

### Verifying Your Setup

You can verify your Vite configuration by checking your `gdk.yml` file:

```shell
gdk config get vite
```

This should display your current Vite settings, including the enabled status and Vue version. Your GDK
should also be up and running.

```shell
---
enabled: true
hot_module_reloading: true
https:
  enabled: true
port: 3038
vue_version: 3
```

### Troubleshooting

#### General Debugging

When encountering issues, start by checking the Vite logs:

```shell
gdk tail vite
```

This shows real-time Vite output and error messages that can help identify the problem.

#### Build Errors After Switching Versions

If you encounter build errors after switching Vue versions:

1. Ensure you've cleared the Vite cache with `yarn clean`
1. Try clearing `node_modules` and reinstalling dependencies:

   ```shell
   rm -rf node_modules
   yarn install
   ```

#### Vite Not Starting

If Vite fails to start:

- Check that `vite.enabled` is set to `true`
- Verify your Node.js version meets Vite's requirements
- Review GDK logs for specific error messages

### Additional Resources

- [Vite Documentation](https://vitejs.dev/)
- [Vue 3 Documentation](https://vuejs.org/)
- [GDK Documentation](https://gitlab.com/gitlab-org/gitlab-development-kit)

## Compatibility changes

### Vue filters

**Why**?

Filters [are removed](https://github.com/vuejs/rfcs/blob/master/active-rfcs/0015-remove-filters.md) from the Vue 3 API completely.

**What to use instead**

Component's computed properties / methods or external helpers.

### Event hub

**Why**?

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

### \<template functional>

**Why**?

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

### Old slots syntax with `slot` attribute

**Why**?

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

### Props default function `this` access

**Why**?

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

[In Vue 3](https://v3-migration.vuejs.org/breaking-changes/props-default-this.html),
the props default value factory is passed the raw props as an argument, and can
also access injections.

### Handling libraries that do not work with `@vue/compat`

**Problem**

Some libraries rely on Vue.js 2 internals. They might not work with `@vue/compat`, so we have added an adapter or replacements as a compatibility layer.

**Goals**

- We should add as few changes as possible to existing code to support new libraries. Instead, we should **add*- new code, which will act as **facade**, making the new version compatible with the old one
- Switching between new and old versions should be hidden inside tooling (webpack / jest) and should not be exposed to the code
- All facades specific to migration should live in the same directory to simplify future migration steps

## Testing

For more information about implementing or fixing tests that fail while using Vue 3, read the
[Vue 3 testing guide](../testing_guide/testing_vue3.md).
