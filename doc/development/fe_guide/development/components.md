# Components

## Icons

In light of our [use gitlab-svgs initative][gitlab-svgs-initative], all new icons should be added to the [gitlab-svgs project][gitlab-svgs-project]. Once new icons are added to the gitlab-svgs project, please have the maintainer update the gitlab-svgs dependency on npm and on gitlab-ce (gitlab-ee will automatically adopt those changes through our CE => EE routine job).

### Using icons in HAML

We've built a helper method `sprite_icon(icon_name, size: nil, css_class: '')` to make it easier to reference the sprite icons in HAML.

- **icon_name** should correspond to the SVG sprite name. If you are unsure of the name, you can filter for the icon names using the [GitLab SVG Previewer][svg-previewer]
- **size (optional)** sets the size of the icon. Valid sizes include 16, 24, 32, 48 and 72. These values will be transformed into it's matching CSS class. E.g. 16 will add a CSS class of `s16`.
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

We've also built a shared component for icon usage in Vue. This shared component is called [icon.vue][icon-vue].

### Using icons in JavaScript

For usage inside JavaScript, we recommend importing [common_utils.js][common-utils] into your module and by calling `spriteIcon(iconName)`. This will return the sprite icon HTML, which you can dynamically add to your page.

## Illustrations

Illustrations are also stored in the `gitlab-svgs` project. They can be referenced in HAML by using the `image_tag` or `image_path` helpers.

```
# Renders the merge request illustration
= image_tag 'illustrations/merge_requests.svg'

# An alternative to rendering the illustration
= image_path 'illustrations/merge_requests.svg'
```

## Dropdown

> Note: There are multiple dropdown implementations in GitLab: Select2, DropLab, glDropdown and Bootstrap dropdowns. We will eventually align to one method for dropdowns but in the meantime, please use whichever one is more convenient.

If you are using Bootstrap dropdowns, please use the following template to ensure that your dropdown styles match our GitLab design.

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

## Modals

In Vue, we have created a reusable component to handle modals. All you have to do is import our [gl-modal component][gl-modal]

```
<gl-modal
    id="dogs-out-modal"
    :header-title-text="'Let the dogs out?'"
    footer-primary-button-variant="danger"
    :footer-primary-button-text="'Let them out'"
    @submit="letOut(theDogs)"
  >
</gl-modal>
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

[gitlab-svgs-initative]: ../initatives.md
[gitlab-svgs-project]: https://gitlab.com/gitlab-org/gitlab-svgs
[svg-previewer]: http://gitlab-org.gitlab.io/gitlab-svgs/
[icon-vue]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/app/assets/javascripts/vue_shared/components/icon.vue
[common-utils]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/app/assets/javascripts/lib/utils/common_utils.js
[gl-modal]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/app/assets/javascripts/vue_shared/components/gl-modal.vue
[ux-modals]: https://docs.gitlab.com/ce/development/ux_guide/components.html#modals
[tooltip-directive]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/app/assets/javascripts/vue_shared/directives/tooltip.js
