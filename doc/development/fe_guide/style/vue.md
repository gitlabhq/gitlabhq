# Vue style guide

We use the official ESLint plugin for Vue.js with the preset of [plugin:vue/recommended][plugin-recommended].

In addition to the style guidelines set by Vue, we also have a few specific rules listed below.

## Structure

- 1.1 **Use vue extension** Use `.vue` extension for Vue components

- 1.2 **Do not use singleton for service or store**

- 1.3 **Separate service into it's own file**

- 1.4 **Separate store into it's own file**

- 1.5 **Initialize root Vue components** Use a function in the bundle file to instantiate Vue components

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

- 1.6 **Tag ordering in vue file** Always define `<script>`, `<template>` and `<style>` (if any)

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

- 1.7 **Imported module names** Imported module names should use `PascalCase`

```
// bad
import cardBoard from 'cardBoard.vue'

// good
import CardBoard from 'cardBoard.vue'
```

## Attributes

- 2.1 **Avoid DOM component prop names**

> TODO: Add good and bad example

- 2.2 **Use kebab-case for prop names** Template prop attribute names should use kebab-case.

```
// bad
<component myProp="prop" />

// good
<component my-prop="prop" />
```

- 2.3 **Multiple attributes** If an element contains more than one attribute, each attribute should be listed on a new line.

```
// bad
<button type="btn" class="btn">
  Click me
</button>

// good
<button
  type="btn"
  class="btn">
  Click me
</button>
```

- 2.4 **Single attributes** If an element has one attribute, the contents (if any), should be on a new line.

```
// bad
<a href="#">Link</a>

// good
<a href="#">
  Link
</a>
```

- 2.5 **Attribute values inside template** Use double quotes for attribute values inside templates.

```
// bad
<img src='#' />

// good
<img src="#" />
```

- 2.6 **Use shorthand** Use the shorthand syntax whenever it is available

```
// bad
<component v-on:click="eventHandler"/>

// good
<component @click="eventHandler"/>
```

- 2.7 **Use self closing tags** If a component or element is self closing, use the self closing tag.

```
// bad
<component></component>

// good
<component />
```


[plugin-recommended]: https://github.com/vuejs/eslint-plugin-vue#gear-configs
