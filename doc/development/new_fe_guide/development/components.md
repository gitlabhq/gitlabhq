# Components

## Icons

In light of our [use gitlab-svgs initiative][gitlab-svgs-initiative], all new icons should be added to the [gitlab-svgs project][gitlab-svgs-project]. Once new icons are added to the gitlab-svgs project, please have the maintainer update the gitlab-svgs dependency on NPM and on gitlab-ce. The gitlab-ee repo will get updated from the automatic CE->EE merge.

### Using icons in HAML

We've built a helper method `sprite_icon(icon_name, size: nil, css_class: '')` to make it easier to reference the sprite icons in HAML.

- **icon_name** should correspond to the SVG sprite name. If you are unsure of the name, you can filter for the icon names using the [GitLab SVG Previewer][svg-previewer]
- **size (optional)** sets the size of the icon. Valid sizes include 16, 24, 32, 48 and 72. These values will be transformed into its matching CSS class. E.g. 16 will add a CSS class of `s16`.
- **css_class (optional)** applies additional css classes to the icon.

```
# HAML
= sprite_icon('issues', size: 72, css_class: 'icon-danger')

# will generate the following
<svg class="s72 icon-danger">
  <use xmlns:xlink="http://www.w3.org/1999/xlink" xlink:href="/assets/icons.svg#issues"></use>
</svg>
```

### Using icons in Vue

We've also built a shared component for icon usage in Vue - [icon.vue][icon-vue].

### Using icons in JavaScript

Import `spriteIcon` from [common_utils.js][common-utils]. Calling `spriteIcon(iconName)` returns the icon HTML, which you can add to your page.

## Illustrations

Illustrations are also stored in the `gitlab-svgs` project. For consistent sizing and padding it can be wrapped in an element with the `svg-content` class.

### In HAML

Illustrations can be referenced using the `image_tag` helper.

**Example**

```haml
.svg-content
  = image_tag 'illustrations/merge_requests.svg'
```

### In Vue

SVGs can be added to templates using `v-html`. We don't need change detection for the SVG, so we add it in the `created` hook rather than using `data`.

```
<script>
import svg from 'images/illustrations/todos_empty.svg';

export default {
  created() {
    this.todosEmptySvg = svg;
  },
};
</script>

<template>
  <div class="svg-content">
    <div v-html="todosEmptySvg"></div>
  </div>
</template>
```

## Dropdowns

> Note: There are multiple dropdown implementations in GitLab: Select2, DropLab, glDropdown and Bootstrap dropdowns. We will eventually align to one method for dropdowns. In the meantime, please use whichever one is more convenient.

If you are using Bootstrap dropdowns, use the following template to ensure that your dropdown styles match our GitLab design.

```
# haml without using ruby helpers
.dropdown.my-dropdown
  %button{ type: 'button', data: { toggle: 'dropdown' }, 'aria-haspopup': true, 'aria-expanded': false }
    %span.dropdown-toggle-text
      Toggle Dropdown
    = icon('chevron-down')

  %ul.dropdown-menu
    %li
      %a
        item!

# haml using ruby helpers
.dropdown.my-dropdown
  = dropdown_toggle('Toogle!', { toggle: 'dropdown' })
  = dropdown_content
    %li
      %a
        item!
```

## Graphs

We have a lot of graphing libraries in our codebase to render graphs. In an effort to improve maintainability, new graphs should use [D3.js](https://d3js.org/). If a new graph is fairly simple, consider implementing it in SVGs or HTML5 canvas.

We chose D3 as our library going forward because of the following features:

* [Tree shaking webpack capabilities.](https://github.com/d3/d3/blob/master/CHANGES.md#changes-in-d3-40)
* [Compatible with vue.js as well as vanilla javascript.](https://github.com/d3/d3/blob/master/CHANGES.md#changes-in-d3-40)

D3 is very popular across many projects outside of GitLab:

* [The New York Times](https://archive.nytimes.com/www.nytimes.com/interactive/2012/02/13/us/politics/2013-budget-proposal-graphic.html)
* [plot.ly](https://plot.ly/)
* [Droptask](https://www.droptask.com/)

Within GitLab, D3 has been used for the following notable features

* [Prometheus graphs](https://docs.gitlab.com/ee/user/project/integrations/prometheus.html)
* Contribution calendars

## Modals

In Vue, we have created a reusable component to handle modals. All you have to do is import [gl-modal component][gl-modal]

```
<gl-modal
  id="dogs-out-modal"
  :header-title-text="'Let the dogs out?'"
  footer-primary-button-variant="danger"
  :footer-primary-button-text="'Let them out'"
  @submit="letOut(theDogs)"
/>
```

> Note: See the [corresponding UX guide][ux-modals] for more details about modals.

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

[gitlab-svgs-initiative]: ../initiatives.md
[gitlab-svgs-project]: https://gitlab.com/gitlab-org/gitlab-svgs
[svg-previewer]: http://gitlab-org.gitlab.io/gitlab-svgs/
[icon-vue]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/app/assets/javascripts/vue_shared/components/icon.vue
[common-utils]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/app/assets/javascripts/lib/utils/common_utils.js
[gl-modal]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/app/assets/javascripts/vue_shared/components/gl_modal.vue
[ux-modals]: https://docs.gitlab.com/ce/development/ux_guide/components.html#modals
[tooltip-directive]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/app/assets/javascripts/vue_shared/directives/tooltip.js
