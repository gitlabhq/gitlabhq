# Components

## Icons

> TODO: Add Info

## Illustrations

> TODO: Add Info

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

[gl-modal]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/app/assets/javascripts/vue_shared/components/gl-modal.vue
[ux-modals]: https://docs.gitlab.com/ce/development/ux_guide/components.html#modals
[tooltip-directive]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/app/assets/javascripts/vue_shared/directives/tooltip.js
