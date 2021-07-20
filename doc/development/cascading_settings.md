---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Cascading Settings

> Introduced in [GitLab 13.11](https://gitlab.com/gitlab-org/gitlab/-/issues/321724).

The cascading settings framework allows groups to essentially inherit settings
values from ancestors (parent group on up the group hierarchy) and from
instance-level application settings. The framework also allows settings values
to be enforced on groups lower in the hierarchy.

Cascading settings can currently only be defined within `NamespaceSetting`, though
the framework may be extended to other objects in the future.

## Add a new cascading setting

Settings are not cascading by default. To define a cascading setting, take the following steps:

1. In the `NamespaceSetting` model, define the new attribute using the `cascading_attr`
   helper method. You can use an array to define multiple attributes on a single line.

    ```ruby
    class NamespaceSetting
      include CascadingNamespaceSettingAttribute

      cascading_attr :delayed_project_removal
    end
    ```

1. Create the database columns.

   You can use the following database migration helper for a completely new setting.
   The helper creates four columns, two each in `namespace_settings` and
   `application_settings`.

    ```ruby
    class AddDelayedProjectRemovalCascadingSetting < ActiveRecord::Migration[6.0]
      include Gitlab::Database::MigrationHelpers::CascadingNamespaceSettings

      def up
        add_cascading_namespace_setting :delayed_project_removal, :boolean, default: false, null: false
      end

      def down
       remove_cascading_namespace_setting :delayed_project_removal
      end
    end
    ```

   Existing settings being converted to a cascading setting will require individual
   migrations to add columns and change existing columns. Use the specifications
   below to create migrations as required:

    1. Columns in `namespace_settings` table:
        - `delayed_project_removal`: No default value. Null values allowed. Use any column type.
        - `lock_delayed_project_removal`: Boolean column. Default value is false. Null values not allowed.
    1. Columns in `application_settings` table:
        - `delayed_project_removal`: Type matching for the column created in `namespace_settings`.
          Set default value as desired. Null values not allowed.
        - `lock_delayed_project_removal`: Boolean column. Default value is false. Null values not allowed.

## Convenience methods

By defining an attribute using the `cascading_attr` method, a number of convenience
methods are automatically defined.

**Definition:**

```ruby
cascading_attr :delayed_project_removal
```

**Convenience Methods Available:**

- `delayed_project_removal`
- `delayed_project_removal=`
- `delayed_project_removal_locked?`
- `delayed_project_removal_locked_by_ancestor?`
- `delayed_project_removal_locked_by_application_setting?`
- `delayed_project_removal?` (Boolean attributes only)
- `delayed_project_removal_locked_ancestor` (Returns locked namespace settings object `[namespace_id]`)

### Attribute reader method (`delayed_project_removal`)

The attribute reader method (`delayed_project_removal`) returns the correct
cascaded value using the following criteria:

1. Returns the dirty value, if the attribute has changed. This allows standard
   Rails validators to be used on the attribute, though `nil` values *must* be allowed.
1. Return locked ancestor value.
1. Return locked instance-level application settings value.
1. Return this namespace's attribute, if not nil.
1. Return value from nearest ancestor where value is not nil.
1. Return instance-level application setting.

### `_locked?` method

By default, the `_locked?` method (`delayed_project_removal_locked?`) returns
`true` if an ancestor of the group or application setting locks the attribute.
It returns `false` when called from the group that locked the attribute.

When `include_self: true` is specified, it returns `true` when called from the group that locked the attribute.
This would be relevant, for example, when checking if an attribute is locked from a project.

## Display cascading settings on the frontend

There are a few Rails view helpers, HAML partials, and JavaScript functions that can be used to display a cascading setting on the frontend.

### Rails view helpers

[`cascading_namespace_setting_locked?`](https://gitlab.com/gitlab-org/gitlab/-/blob/c2736823b8e922e26fd35df4f0cd77019243c858/app/helpers/namespaces_helper.rb#L86)

Calls through to the [`_locked?` method](#_locked-method) to check if the setting is locked.

| Argument    | Description                                                                      | Type                                                                              | Required (default value) |
|:------------|:---------------------------------------------------------------------------------|:----------------------------------------------------------------------------------|:-------------------------|
| `attribute` | Name of the setting. For example, `:delayed_project_removal`.                    | `String` or `Symbol`                                                              | `true`                   |
| `group`     | Current group.                                                                   | [`Group`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/group.rb) | `true`                   |
| `**args`    | Additional arguments to pass through to the [`_locked?` method](#_locked-method) |                                                                                   | `false`                  |

### HAML partials

[`_enforcement_checkbox.html.haml`](https://gitlab.com/gitlab-org/gitlab/-/blob/c2736823b8e922e26fd35df4f0cd77019243c858/app/views/shared/namespaces/cascading_settings/_enforcement_checkbox.html.haml)

Renders the enforcement checkbox.

| Local            | Description                                                                                                                                                                                                                                                | Type                                                                                           | Required (default value)                        |
|:-----------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------|:------------------------------------------------|
| `attribute`      | Name of the setting. For example, `:delayed_project_removal`.                                                                                                                                                                                              | `String` or `Symbol`                                                                           | `true`                                          |
| `group`     | Current group. | [`Group`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/group.rb) | `true` |
| `form`           | [Rails FormBuilder object](https://apidock.com/rails/ActionView/Helpers/FormBuilder).                                                                                                                                                                      | [`ActionView::Helpers::FormBuilder`](https://apidock.com/rails/ActionView/Helpers/FormBuilder) | `true`                                          |
| `setting_locked` | If the setting is locked by an ancestor group or admin setting. Can be calculated with [`cascading_namespace_setting_locked?`](https://gitlab.com/gitlab-org/gitlab/-/blob/c2736823b8e922e26fd35df4f0cd77019243c858/app/helpers/namespaces_helper.rb#L86). | `Boolean`                                                                                      | `true`                                          |
| `help_text`      | Text shown below the checkbox.                                                                                                                                                                                                                             | `String`                                                                                       | `false` (Subgroups cannot change this setting.) |

[`_setting_label_checkbox.html.haml`](https://gitlab.com/gitlab-org/gitlab/-/blob/c2736823b8e922e26fd35df4f0cd77019243c858/app/views/shared/namespaces/cascading_settings/_setting_label_checkbox.html.haml)

Renders the label for a checkbox setting.

| Local                  | Description                                                                                                                                                                                                                                                | Type                                                                                           | Required (default value) |
|:-----------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------|:-------------------------|
| `attribute`            | Name of the setting. For example, `:delayed_project_removal`.                                                                                                                                                                                              | `String` or `Symbol`                                                                           | `true`                   |
| `group`     | Current group. | [`Group`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/group.rb) | `true` |
| `form`                 | [Rails FormBuilder object](https://apidock.com/rails/ActionView/Helpers/FormBuilder).                                                                                                                                                                      | [`ActionView::Helpers::FormBuilder`](https://apidock.com/rails/ActionView/Helpers/FormBuilder) | `true`                   |
| `setting_locked`       | If the setting is locked by an ancestor group or admin setting. Can be calculated with [`cascading_namespace_setting_locked?`](https://gitlab.com/gitlab-org/gitlab/-/blob/c2736823b8e922e26fd35df4f0cd77019243c858/app/helpers/namespaces_helper.rb#L86). | `Boolean`                                                                                      | `true`                   |
| `settings_path_helper` | Lambda function that generates a path to the ancestor setting. For example, `settings_path_helper: -> (locked_ancestor) { edit_group_path(locked_ancestor, anchor: 'js-permissions-settings') }`                                                           | `Lambda`                                                                                       | `true`                   |
| `help_text`            | Text shown below the checkbox.                                                                                                                                                                                                                             | `String`                                                                                       | `false` (`nil`)          |

[`_setting_label_fieldset.html.haml`](https://gitlab.com/gitlab-org/gitlab/-/blob/c2736823b8e922e26fd35df4f0cd77019243c858/app/views/shared/namespaces/cascading_settings/_setting_label_fieldset.html.haml)

Renders the label for a fieldset setting.

| Local                  | Description                                                                                                                                                                                                          | Type                 | Required (default value) |
|:-----------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:---------------------|:-------------------------|
| `attribute`            | Name of the setting. For example, `:delayed_project_removal`.                                                                                                                                                        | `String` or `Symbol` | `true`                   |
| `group`     | Current group. | [`Group`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/group.rb) | `true` |
| `setting_locked`       | If the setting is locked. Can be calculated with [`cascading_namespace_setting_locked?`](https://gitlab.com/gitlab-org/gitlab/-/blob/c2736823b8e922e26fd35df4f0cd77019243c858/app/helpers/namespaces_helper.rb#L86). | `Boolean`            | `true`                   |
| `settings_path_helper` | Lambda function that generates a path to the ancestor setting. For example, `-> (locked_ancestor) { edit_group_path(locked_ancestor, anchor: 'js-permissions-settings') }`                                           | `Lambda`             | `true`                   |
| `help_text`            | Text shown below the checkbox.                                                                                                                                                                                       | `String`             | `false` (`nil`)          |

[`_lock_popovers.html.haml`](https://gitlab.com/gitlab-org/gitlab/-/blob/b73353e47e283a7d9c9eda5bdedb345dcfb685b6/app/views/shared/namespaces/cascading_settings/_lock_popovers.html.haml)

Renders the mount element needed to initialize the JavaScript used to display the popover when hovering over the lock icon. This partial is only needed once per page.

### JavaScript

[`initCascadingSettingsLockPopovers`](https://gitlab.com/gitlab-org/gitlab/-/blob/b73353e47e283a7d9c9eda5bdedb345dcfb685b6/app/assets/javascripts/namespaces/cascading_settings/index.js#L4)

Initializes the JavaScript needed to display the popover when hovering over the lock icon (**{lock}**).
This function should be imported and called in the [page-specific JavaScript](fe_guide/performance.md#page-specific-javascript).

### Put it all together

```haml
-# app/views/groups/edit.html.haml

= render 'shared/namespaces/cascading_settings/lock_popovers'

- delayed_project_removal_locked = cascading_namespace_setting_locked?(:delayed_project_removal, @group)
- merge_method_locked = cascading_namespace_setting_locked?(:merge_method, @group)

= form_for @group do |f|
  .form-group{ data: { testid: 'delayed-project-removal-form-group' } }
    .gl-form-checkbox.custom-control.custom-checkbox
      = f.check_box :delayed_project_removal, checked: @group.namespace_settings.delayed_project_removal?, disabled: delayed_project_removal_locked, class: 'custom-control-input'
      = render 'shared/namespaces/cascading_settings/setting_label_checkbox', attribute: :delayed_project_removal,
          group: @group,
          form: f,
          setting_locked: delayed_project_removal_locked,
          settings_path_helper: -> (locked_ancestor) { edit_group_path(locked_ancestor, anchor: 'js-permissions-settings') },
          help_text: s_('Settings|Projects will be permanently deleted after a 7-day delay. Inherited by subgroups.') do
        = s_('Settings|Enable delayed project removal')
      = render 'shared/namespaces/cascading_settings/enforcement_checkbox',
          attribute: :delayed_project_removal,
          group: @group,
          form: f,
          setting_locked: delayed_project_removal_locked

  %fieldset.form-group
    = render 'shared/namespaces/cascading_settings/setting_label_fieldset', attribute: :merge_method,
        group: @group,
        setting_locked: merge_method_locked,
        settings_path_helper: -> (locked_ancestor) { edit_group_path(locked_ancestor, anchor: 'js-permissions-settings') },
        help_text: s_('Settings|Determine what happens to the commit history when you merge a merge request.') do
      = s_('Settings|Merge method')

    .gl-form-radio.custom-control.custom-radio
      = f.radio_button :merge_method, :merge, class: "custom-control-input", disabled: merge_method_locked
      = f.label :merge_method_merge, class: 'custom-control-label' do
        = s_('Settings|Merge commit')
        %p.help-text
          = s_('Settings|Every merge creates a merge commit.')

    .gl-form-radio.custom-control.custom-radio
      = f.radio_button :merge_method, :rebase_merge, class: "custom-control-input", disabled: merge_method_locked
      = f.label :merge_method_rebase_merge, class: 'custom-control-label' do
        = s_('Settings|Merge commit with semi-linear history')
        %p.help-text
          = s_('Settings|Every merge creates a merge commit.')

    .gl-form-radio.custom-control.custom-radio
      = f.radio_button :merge_method, :ff, class: "custom-control-input", disabled: merge_method_locked
      = f.label :merge_method_ff, class: 'custom-control-label' do
        = s_('Settings|Fast-forward merge')
        %p.help-text
          = s_('Settings|No merge commits are created.')

    = render 'shared/namespaces/cascading_settings/enforcement_checkbox',
      attribute: :merge_method,
      group: @group,
      form: f,
      setting_locked: merge_method_locked
```

```javascript
// app/assets/javascripts/pages/groups/edit/index.js

import { initCascadingSettingsLockPopovers } from '~/namespaces/cascading_settings';

initCascadingSettingsLockPopovers();
```
