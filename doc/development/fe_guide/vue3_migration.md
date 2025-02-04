---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Migration to Vue 3
---

The migration from Vue 2 to 3 is tracked in epic [&6252](https://gitlab.com/groups/gitlab-org/-/epics/6252).

To ease migration to Vue 3.x, we have added [ESLint rules](https://gitlab.com/gitlab-org/frontend/eslint-plugin/-/merge_requests/50)
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

[In Vue 3](https://v3-migration.vuejs.org/breaking-changes/props-default-this.html),
the props default value factory is passed the raw props as an argument, and can
also access injections.

## Handling libraries that do not work with `@vue/compat`

**Problem**

Some libraries rely on Vue.js 2 internals. They might not work with `@vue/compat`, so we need a strategy to use an updated version with Vue.js 3 while maintaining compatibility with the current codebase.

**Goals**

- We should add as few changes as possible to existing code to support new libraries. Instead, we should **add*- new code, which will act as **facade**, making the new version compatible with the old one
- Switching between new and old versions should be hidden inside tooling (webpack / jest) and should not be exposed to the code
- All facades specific to migration should live in the same directory to simplify future migration steps

### Step-by-step migration

In the step-by-step guide, we will be migrating [VueApollo Demo](https://gitlab.com/gitlab-org/frontend/vue3-migration-vue-apollo/-/tree/main/src/vue3compat) project. It will allow us to focus on migration specifics while avoiding nuances of complex tooling setup in the GitLab project. The project intentionally uses the same tooling as GitLab:

- webpack
- yarn
- Vue.js + VueApollo

#### Initial state

Right after cloning, you could run [VueApollo Demo](https://gitlab.com/gitlab-org/frontend/vue3-migration-vue-apollo/-/tree/main/src/vue3compat) with Vue.js 2 using `yarn serve` or with Vue.js 3 (`compat` build) using `yarn serve:vue3`. However latter immediately crashes:

```javascript
Uncaught TypeError: Cannot read properties of undefined (reading 'loading')
```

VueApollo v3 (used for Vue.js 2) fails to initialize in Vue.js `compat`

NOTE:
While stubbing `Vue.version` will solve VueApollo-related issues in the demo project, it will still lose reactivity on specific scenarios, so an upgrade is still needed

#### Step 1. Perform upgrade according to library docs

According to [VueApollo v4 installation guide](https://v4.apollo.vuejs.org/guide/installation.html), we need to install `@vue/apollo-option` (this package provides VueApollo support for Options API) and make changes to our application:

```diff
--- a/src/index.js
+++ b/src/index.js
@@ -1,19 +1,17 @@
-import Vue from "vue";
-import VueApollo from "vue-apollo";
+import { createApp, h } from "vue";
+import { createApolloProvider } from "@vue/apollo-option";

 import Demo from "./components/Demo.vue";
 import createDefaultClient from "./lib/graphql";

-Vue.use(VueApollo);
-
-const apolloProvider = new VueApollo({
+const apolloProvider = createApolloProvider({
   defaultClient: createDefaultClient(),
 });

-new Vue({
-  el: "#app",
-  apolloProvider,
-  render(h) {
+const app = createApp({
+  render() {
     return h(Demo);
   },
 });
+app.use(apolloProvider);
+app.mount("#app");
```

You can view these changes in [01-upgrade-vue-apollo](https://gitlab.com/gitlab-org/frontend/vue3-migration-vue-apollo/-/compare/main...01-upgrade-vue-apollo) branch of demo project

#### Step 2. Addressing differences in augmenting applications in Vue.js 2 and 3

In Vue.js 2 tooling like `VueApollo` is initialized in a "lazy" fashion:

```javascript
// We are registering VueApollo "handler" to handle some data LATER
Vue.use(VueApollo)
// ...
// apolloProvider is provided at app instantiation,
// previously registered VueApollo will handle that
new Vue({ /- ... */, apolloProvider })
```

In Vue.js 3 both steps were merged in one - we are immediately registering the handler and passing configuration:

```javascript
app.use(apolloProvider)
```

In order to backport this behavior, we need the following knowledge:

- We can access extra options provided to Vue instance via `$options`, so extra `apolloProvider` will be visible as `this.$options.apolloProvider`
- We can access the current `app` (in Vue.js 3 meaning) on the Vue instance via `this.$.appContext.app`

NOTE:
We're relying on non-public Vue.js 3 API in this case. However, since `@vue/compat` builds are expected to be available only for 3.2.x branch, we have reduced risks that this API will be changed

With this knowledge, we can move the initialization of our tooling as early as possible in Vue2 - in the `beforeCreate()` lifecycle hook:

```diff
--- a/src/index.js
+++ b/src/index.js
@@ -1,4 +1,4 @@
-import { createApp, h } from "vue";
+import Vue from "vue";
 import { createApolloProvider } from "@vue/apollo-option";

 import Demo from "./components/Demo.vue";
@@ -8,10 +8,13 @@ const apolloProvider = createApolloProvider({
   defaultClient: createDefaultClient(),
 });

-const app = createApp({
-  render() {
+new Vue({
+  el: "#app",
+  apolloProvider,
+  render(h) {
     return h(Demo);
   },
+  beforeCreate() {
+    this.$.appContext.app.use(this.$options.apolloProvider);
+  },
 });
-app.use(apolloProvider);
-app.mount("#app");
```

You can view these changes in [02-bring-back-new-vue](https://gitlab.com/gitlab-org/frontend/vue3-migration-vue-apollo/-/compare/01-upgrade-vue-apollo...02-bring-back-new-vue) branch of demo project

#### Step 3. Recreating `VueApollo` class

Vue.js 3 libraries (and Vue.js itself) have a preference for using factories like `createApp` instead of classes (previously `new Vue`)

`VueApollo` class served two purposes:

- constructor for creating `apolloProvider`
- installation of apollo-related logic in components

We can utilize `Vue.use(VueApollo)` code, which existed in our codebase, to hide there our mixin and avoid modification of our app code:

```diff
--- a/src/index.js
+++ b/src/index.js
@@ -4,7 +4,26 @@ import { createApolloProvider } from "@vue/apollo-option";
 import Demo from "./components/Demo.vue";
 import createDefaultClient from "./lib/graphql";

-const apolloProvider = createApolloProvider({
+class VueApollo {
+  constructor(...args) {
+    return createApolloProvider(...args);
+  }
+
+  // called by Vue.use
+  static install() {
+    Vue.mixin({
+      beforeCreate() {
+        if (this.$options.apolloProvider) {
+          this.$.appContext.app.use(this.$options.apolloProvider);
+        }
+      },
+    });
+  }
+}
+
+Vue.use(VueApollo);
+
+const apolloProvider = new VueApollo({
   defaultClient: createDefaultClient(),
 });

@@ -14,7 +33,4 @@ new Vue({
   render(h) {
     return h(Demo);
   },
-  beforeCreate() {
-    this.$.appContext.app.use(this.$options.apolloProvider);
-  },
 });
```

You can view these changes in [03-recreate-vue-apollo](https://gitlab.com/gitlab-org/frontend/vue3-migration-vue-apollo/-/compare/02-bring-back-new-vue...03-recreate-vue-apollo) branch of demo project

#### Step 4. Moving `VueApollo` class to a separate file and setting up an alias

Now, we have almost the same code (excluding import) as in Vue.js 2 version.
We will move our facade to the separate file and set up `webpack` conditionally execute it if `vue-apollo` is imported when using Vue.js 3:

```diff
--- a/src/index.js
+++ b/src/index.js
@@ -1,5 +1,5 @@
 import Vue from "vue";
-import { createApolloProvider } from "@vue/apollo-option";
+import VueApollo from "vue-apollo";

 import Demo from "./components/Demo.vue";
 import createDefaultClient from "./lib/graphql";
diff --git a/webpack.config.js b/webpack.config.js
index 6160d3f..b8b955f 100644
--- a/webpack.config.js
+++ b/webpack.config.js
@@ -12,6 +12,7 @@ if (USE_VUE3) {

   VUE3_ALIASES = {
     vue: "@vue/compat",
+    "vue-apollo": path.resolve("src/vue3compat/vue-apollo"),
   };
 }
```

(moving `VueApollo` class from `index.js` to `vue3compat/vue-apollo.js` as default export is omitted for clarity)

You can view these changes in [04-add-webpack-alias](https://gitlab.com/gitlab-org/frontend/vue3-migration-vue-apollo/-/compare/03-recreate-vue-apollo...04-add-webpack-alias) branch of demo project

#### Step 5. Observe the results

At this point, you should be able again to run **both*- Vue.js 2 version with `yarn serve` and Vue.js 3 one with `yarn serve:vue3`
[Final MR](https://gitlab.com/gitlab-org/frontend/vue3-migration-vue-apollo/-/merge_requests/1/diffs) with all changes from previous steps displays no changes to `index.js` (application code), which was our goal

### Applying this approach in the GitLab project

In [commit adding VueApollo v4 support](https://gitlab.com/gitlab-org/gitlab/-/commit/e0af7e6479695a28a4fe85a88f90815aa3ce2814) we can see additional nuances not covered by step-by-step guide:

- We might need to add additional imports to our facades (our code in GitLab uses `ApolloMutation` component)
- We need to update aliases not only for webpack but also for jest so our tests could also consume our facade

## Unit testing

For more information about implementing unit tests or fixing tests that fail while using Vue 3,
read the [Vue 3 testing guide](../testing_guide/testing_vue3.md).
