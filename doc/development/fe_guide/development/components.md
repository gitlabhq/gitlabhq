# Components

## Icons

> TODO: Add Info

## Illustrations

> TODO: Add Info

## Dropdown

> TODO: Add Info

## Modals

> TODO: Add Info

## Tooltips

In HTML, we initialize tooltips on elements by adding the `.has-tooltip` CSS class and by adding an attribute `title`. The underlying implementation of these tooltips uses Bootstrap Tooltips.

```
<!-- Tooltip will read: Hello world -->
<span class="has-tooltip" title="Hello world"></span>
```

In Vue, we initialize tooltips by importing our [tooltip directive][tooltip-directive] to our desired Vue file and by adding the `v-tooltip` and `title` attributes to the desired element.

```
<!-- Tooltip will read: Hello world -->
<span
  v-tooltip
  title="Hello world"
>
</span>
```

[tooltip-directive]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/app/assets/javascripts/vue_shared/directives/tooltip.js
