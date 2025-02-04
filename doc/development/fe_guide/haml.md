---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: HAML
---

[HAML](https://haml.info/) is the [Ruby on Rails](https://rubyonrails.org/) template language that GitLab uses.

## HAML and our Pajamas Design System

[GitLab UI](https://gitlab-org.gitlab.io/gitlab-ui/) is a Vue component library that conforms
to the [Pajamas design system](https://design.gitlab.com/). Many of these components
rely on JavaScript and therefore can only be used in Vue.

However, some of the simpler components (such as buttons, checkboxes, or form inputs) can be
used in HAML:

- Some of the Pajamas components are available as a [ViewComponent](view_component.md#pajamas-components). Use these when possible.
- If no ViewComponent exists, why not go ahead and create it? Talk to the [Design System](https://handbook.gitlab.com/handbook/engineering/development/dev/foundations/design-system/) team if you need help.
- As a fallback, this can be done by applying the correct CSS classes to the elements.
- A custom [Ruby on Rails form builder](https://gitlab.com/gitlab-org/gitlab/-/blob/7c108df101e86d8a27d69df2b5b1ff1fc24133c5/lib/gitlab/form_builders/gitlab_ui_form_builder.rb)
  exists to help use GitLab UI components in HAML forms.

### Use the GitLab UI form builder

To use the GitLab UI form builder:

1. Change `form_for` to `gitlab_ui_form_for`.
1. Change `f.check_box` to `f.gitlab_ui_checkbox_component`.
1. Remove `f.label` and instead pass the label as the second argument in `f.gitlab_ui_checkbox_component`.

For example:

- Before:

  ```haml
  = form_for @group do |f|
    .form-group.gl-mb-3
      .gl-form-checkbox.custom-control.custom-checkbox
        = f.check_box :prevent_sharing_groups_outside_hierarchy, disabled: !can_change_prevent_sharing_groups_outside_hierarchy?(@group), class: 'custom-control-input'
        = f.label :prevent_sharing_groups_outside_hierarchy, class: 'custom-control-label' do
          %span
            = safe_format(s_('GroupSettings|Prevent members from sending invitations to groups outside of %{group} and its subgroups.'), group: link_to_group(@group))
          %p.help-text= prevent_sharing_groups_outside_hierarchy_help_text(@group)

    .form-group.gl-mb-3
      .gl-form-checkbox.custom-control.custom-checkbox
        = f.check_box :lfs_enabled, checked: @group.lfs_enabled?, class: 'custom-control-input'
        = f.label :lfs_enabled, class: 'custom-control-label' do
          %span
            = _('Allow projects within this group to use Git LFS')
            = link_to sprite_icon('question-o'), help_page_path('topics/git/lfs/index')
          %p.help-text= _('This setting can be overridden in each project.')
  ```

- After:

  ```haml
  = gitlab_ui_form_for @group do |f|
    .form-group.gl-mb-3
      = f.gitlab_ui_checkbox_component :prevent_sharing_groups_outside_hierarchy,
          safe_format(s_('GroupSettings|Prevent members from sending invitations to groups outside of %{group} and its subgroups.'), group: link_to_group(@group)),
          help_text: prevent_sharing_groups_outside_hierarchy_help_text(@group),
          checkbox_options: { disabled: !can_change_prevent_sharing_groups_outside_hierarchy?(@group) }

    .form-group.gl-mb-3
      = f.gitlab_ui_checkbox_component :lfs_enabled, checkbox_options: { checked: @group.lfs_enabled? } do |c|
        - c.with_label do
          = _('Allow projects within this group to use Git LFS')
          = link_to sprite_icon('question-o'), help_page_path('topics/git/lfs/index')
        - c.with_help_text do
          = _('This setting can be overridden in each project.')
  ```

### Available components

When using the GitLab UI form builder, the following components are available for use in HAML.

NOTE:
Currently only the listed components are available but more components are planned.

#### `gitlab_ui_checkbox_component`

[GitLab UI Docs](https://gitlab-org.gitlab.io/gitlab-ui/?path=/story/base-form-form-checkbox--default)

##### Arguments

| Argument | Description | Type | Required (default value) |
|---|---|---|---|
| `method` | Attribute on the object passed to `gitlab_ui_form_for`. | `Symbol` | `true` |
| `label` | Checkbox label. `label` slot can be used instead of this argument if HTML is needed. | `String` | `false` (`nil`) |
| `help_text` | Help text displayed below the checkbox. `help_text` slot can be used instead of this argument if HTML is needed. | `String` | `false` (`nil`) |
| `checkbox_options` | Options that are passed to [Rails `check_box` method](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-check_box). | `Hash` | `false` (`{}`) |
| `checked_value` | Value when checkbox is checked. | `String` | `false` (`'1'`) |
| `unchecked_value` | Value when checkbox is unchecked. | `String` | `false` (`'0'`) |
| `label_options` | Options that are passed to [Rails `label` method](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-label). | `Hash` | `false` (`{}`) |

##### Slots

This component supports [ViewComponent slots](https://viewcomponent.org/guide/slots.html).

| Slot | Description |
|---|---|
| `label` | Checkbox label content. This slot can be used instead of the `label` argument. |
| `help_text` | Help text content displayed below the checkbox. This slot can be used instead of the `help_text` argument. |

#### `gitlab_ui_radio_component`

[GitLab UI Docs](https://gitlab-org.gitlab.io/gitlab-ui/?path=/story/base-form-form-radio--default)

##### Arguments

| Argument | Description | Type | Required (default value) |
|---|---|---|---|
| `method` | Attribute on the object passed to `gitlab_ui_form_for`. | `Symbol` | `true` |
| `value` | The value of the radio tag. | `Symbol` | `true` |
| `label` | Radio label. `label` slot can be used instead of this argument if HTML content is needed inside the label. | `String` | `false` (`nil`) |
| `help_text` | Help text displayed below the radio button. `help_text` slot can be used instead of this argument if HTML content is needed inside the help text. | `String` | `false` (`nil`) |
| `radio_options` | Options that are passed to [Rails `radio_button` method](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-radio_button). | `Hash` | `false` (`{}`) |
| `label_options` | Options that are passed to [Rails `label` method](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html#method-i-label). | `Hash` | `false` (`{}`) |

##### Slots

This component supports [ViewComponent slots](https://viewcomponent.org/guide/slots.html).

| Slot | Description |
|---|---|
| `label` | Checkbox label content. This slot can be used instead of the `label` argument. |
| `help_text` | Help text content displayed below the radio button. This slot can be used instead of the `help_text` argument. |
