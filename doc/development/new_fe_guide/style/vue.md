# Vue style guide

We use the official ESLint plugin for Vue.js with the preset of [plugin:vue/recommended][plugin-recommended].

In addition to the style guidelines set by Vue, we also have a few specific rules listed below.

## Structure

<a name="vue-extension"></a><a name="1.1"></a>
- [1.1](#vue-extension) **Use vue extension** Use `.vue` extension for Vue components

<a name="no-singleton"></a><a name="1.2"></a>
- [1.2](#no-singleton) **Do not use singleton for service or store**.

<a name="init"></a><a name="1.3"></a>
- [1.3](#init) **Initialize root Vue components** Use a function in the bundle file to instantiate Vue components

```
// bad
class {
  init() {
    new Component({})
  }
}

// good
document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '#element',
  components: {
    componentName,
  },
  render: createElement => createElement('component-name'),
}));
```

<a name="tag-order"></a><a name="1.4"></a>
- [1.6](#tag-order) **Tag ordering in vue file** Always define `<script>`, `<template>` and `<style>` (if any)

```
<script>
  // ...
</script>

<template>
  // ...
</template>

// We don't use scoped styles but there are few instances of this
<style>
  // ...
</style>
```

## Attributes

<a name="dom-prop"></a><a name="2.1"></a>
- [2.1](#dom-prop) **Avoid DOM component prop names**

```
// bad
<component title="prop" />

// good
<component my-prop="prop" />
```

[plugin-recommended]: https://github.com/vuejs/eslint-plugin-vue#gear-configs
