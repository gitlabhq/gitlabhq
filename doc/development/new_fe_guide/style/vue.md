# Vue style guide

We use the official ESLint plugin for Vue.js with the preset of [plugin:vue/recommended][plugin-recommended].

In addition to the style guidelines set by Vue, we also have a few specific rules listed below.

## Structure

<a name="vue-extension"></a><a name="1.1"></a>
- [1.1](#vue-extension) **Use vue extension** Use `.vue` extension for Vue components

<a name="no-singleton"></a><a name="1.2"></a>
- [1.2](#no-singleton) **Do not use singleton for service or store**

<a name="service-file"></a><a name="1.3"></a>
- [1.3](#service-file) **Separate service into it's own file**

<a name="store-file"></a><a name="1.4"></a>
- [1.4](#store-file) **Separate store into it's own file**

<a name="init"></a><a name="1.5"></a>
- [1.5](#init) **Initialize root Vue components** Use a function in the bundle file to instantiate Vue components

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

<a name="tag-order"></a><a name="1.6"></a>
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

<a name="import-name"></a><a name="1.7"></a>
- [1.7](#import-name) **Imported module names** Imported module names should use `PascalCase`

```
// bad
import cardBoard from 'cardBoard.vue'

// good
import CardBoard from 'cardBoard.vue'
```

## Attributes

<a name="dom-prop"></a><a name="2.1"></a>
- [2.1](#dom-prop) **Avoid DOM component prop names**

> TODO: Add good and bad example

<a name="kebab-prop"></a><a name="2.2"></a>
- [2.2](#kebab-prop) **Use kebab-case for prop names** Template prop attribute names should use kebab-case.

```
// bad
<component myProp="prop" />

// good
<component my-prop="prop" />
```

<a name="template-attr"></a><a name="2.3"></a>
- [2.3](#template-attr) **Attribute values inside template** Use double quotes for attribute values inside templates.

```
// bad
<img src='#' />

// good
<img src="#" />
```

<a name="shorthand"></a><a name="2.4"></a>
- [2.4](#shorthand) **Use shorthand** Use the shorthand syntax whenever it is available

```
// bad
<component v-on:click="eventHandler"/>

// good
<component @click="eventHandler"/>
```

<a name="self-closing"></a><a name="2.5"></a>
- [2.5](#self-closing) **Use self closing tags** If a component or element is self closing, use the self closing tag.

```
// bad
<component></component>

// good
<component />
```

[plugin-recommended]: https://github.com/vuejs/eslint-plugin-vue#gear-configs
