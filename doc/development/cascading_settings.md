---
stage: Foundations
group: Personal Productivity
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Cascading Settings
---

Have you ever wanted to add a setting on a GitLab project and/or group that had a default value that was inherited from a parent in the hierarchy?

If so: we have the framework you have been seeking!

The cascading settings framework allows groups and projects to inherit settings
values from ancestors (parent group on up the group hierarchy) and from
instance-level application settings. The framework also allows settings values
to be "locked" (enforced) on groups lower in the hierarchy.

Cascading settings historically have only been defined on `ApplicationSetting`, `NamespaceSetting` and `ProjectSetting`, though
the framework may be extended to other objects in the future.

## Add a new cascading setting to groups only

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
   class AddDelayedProjectRemovalCascadingSetting < Gitlab::Database::Migration[2.1]
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

## Add a new cascading setting to projects

### Background

The first iteration of the cascading settings framework was for instance and group-level settings only.

Later on, there was a need to add this setting to projects as well. Projects in GitLab also have namespaces, so you might think it would be easy to extend the existing framework to projects by using the same column in the `namespace_settings` table that was added for the group-level setting. But, it made more sense to add cascading project settings to the `project_settings` table.

Why, you may ask? Well, because it turns out that:

- Every user, project, and group in GitLab belongs to a namespace
- Namespace `has_one` namespace_settings record
- When a group or user is created, its namespace + namespace settings are created via service objects ([code](https://gitlab.com/gitlab-org/gitlab/-/blob/4ec1107b20e75deda9c63ede7108b03cbfcc0cf2/app/services/groups/create_service.rb#L20)).
- When a project is created, a namespace is created but no namespace settings are created.

In addition, we do not expose project-level namespace settings in the GitLab UI anywhere. Instead, we use project settings. One day, we hope to be able to use namespace settings for project settings. But today, it is easier to add project-level settings to the `project_settings` table.

### Implementation

An example of adding a cascading setting to a project is in [MR 149931](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144931).

## Cascading setting values on write

The only cascading setting that actually cascades values at the database level in the new recommended way is `duo_features_enabled`. That setting cascades from groups to projects. [Issue 505335](https://gitlab.com/gitlab-org/gitlab/-/issues/505335) describes adding this cascading from the application level to groups as well.

### Legacy cascading settings writes

In the first iteration of the cascading settings framework, the "cascade" was as the application code-level, not the database level. The way this works is that the setting value in the `application_settings` table has a default value. At the `namespace_settings` level, it does not. As a result, namespaces have a `nil` value at the database level but "inherit" the `application_settings` value.

If the group is updated to have a new setting value, that takes precedent over the default value at the `application_settings` level. And, any subgroups will inherit the parent group's setting value because they also have a `nil` value at the database level but inherit the parent value from the `namespace_settings` table. If one of the subgroups update the setting, however, then that overrides the parent group.

This introduces some potentially confusing logic.

If the setting value changes at the `application_settings` level:

- Any root-level groups that have the setting value set to `nil` will inherit the new value.
- Any root-level groups that have the setting value set to a value other than `nil` will not inherit the new value.

If the setting value changes at the `namespace_settings` level:

- Any subgroups or projects that have the setting value set to `nil` will inherit the new value from the parent group.
- Any subgroups or projects that have the setting value set to a value other than `nil` will not inherit the new value from the parent group.

Because the database-level values cannot be seen in the UI or by using the API (because those both show the inherited value), an instance or group admin may not understand which groups/projects inherit the value or not.

The exception to the inconsistent cascading behavior is if the setting is `locked`. This always "forces" inheritance.

In addition to the confusing logic, this also creates a performance problem whenever the value is read: if the settings value is queried for a deeply nested hierarchy, the settings value for the whole hierarchy may need to be read to know the setting value.

### Recommendation for cascading settings writes going forward

To provide a clearer logic chain and improve performance, you should be adding default values to newly-added cascading settings and doing a write on all child objects in the hierarchy when the setting value is updated. This requires kicking off a job so that the update happens asynchronously. An example of how to do this is in [MR 145876](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145876).

Cascading settings that were added previously still have default `nil` values and read the ancestor hierarchy to find inherited settings values. But to minimize confusion we should update those to cascade on write. [Issue 483143](https://gitlab.com/gitlab-org/gitlab/-/issues/483143) describes this maintenance task.

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
| `setting_locked` | If the setting is locked by an ancestor group or administrator setting. Can be calculated with [`cascading_namespace_setting_locked?`](https://gitlab.com/gitlab-org/gitlab/-/blob/c2736823b8e922e26fd35df4f0cd77019243c858/app/helpers/namespaces_helper.rb#L86). | `Boolean`                                                                                      | `true`                                          |
| `help_text`      | Text shown below the checkbox.                                                                                                                                                                                                                             | `String`                                                                                       | `false` (Subgroups cannot change this setting.) |

[`_setting_checkbox.html.haml`](https://gitlab.com/gitlab-org/gitlab/-/blob/e915f204f9eb5930760722ce28b4db60b1159677/app/views/shared/namespaces/cascading_settings/_setting_checkbox.html.haml)

Renders the label for a checkbox setting.

| Local                  | Description                                                                                                                                                                                                                                                | Type                                                                                           | Required (default value) |
|:-----------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------|:-------------------------|
| `attribute`            | Name of the setting. For example, `:delayed_project_removal`.                                                                                                                                                                                              | `String` or `Symbol`                                                                           | `true`                   |
| `group`     | Current group. | [`Group`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/group.rb) | `true` |
| `form`                 | [Rails FormBuilder object](https://apidock.com/rails/ActionView/Helpers/FormBuilder).                                                                                                                                                                      | [`ActionView::Helpers::FormBuilder`](https://apidock.com/rails/ActionView/Helpers/FormBuilder) | `true`                   |
| `setting_locked`       | If the setting is locked by an ancestor group or administrator setting. Can be calculated with [`cascading_namespace_setting_locked?`](https://gitlab.com/gitlab-org/gitlab/-/blob/c2736823b8e922e26fd35df4f0cd77019243c858/app/helpers/namespaces_helper.rb#L86). | `Boolean`                                                                                      | `true`                   |
| `settings_path_helper` | Lambda function that generates a path to the ancestor setting. For example, `settings_path_helper: -> (locked_ancestor) { edit_group_path(locked_ancestor, anchor: 'js-permissions-settings') }`                                                           | `Lambda`                                                                                       | `true`                   |
| `help_text`            | Text shown below the checkbox.                                                                                                                                                                                                                             | `String`                                                                                       | `false` (`nil`)          |

[`_setting_label_fieldset.html.haml`](https://gitlab.com/gitlab-org/gitlab/-/blob/c2736823b8e922e26fd35df4f0cd77019243c858/app/views/shared/namespaces/cascading_settings/_setting_label_fieldset.html.haml)

Renders the label for a `fieldset` setting.

| Local                  | Description                                                                                                                                                                                                          | Type                 | Required (default value) |
|:-----------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:---------------------|:-------------------------|
| `attribute`            | Name of the setting. For example, `:delayed_project_removal`.                                                                                                                                                        | `String` or `Symbol` | `true`                   |
| `group`     | Current group. | [`Group`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/group.rb) | `true` |
| `setting_locked`       | If the setting is locked. Can be calculated with [`cascading_namespace_setting_locked?`](https://gitlab.com/gitlab-org/gitlab/-/blob/c2736823b8e922e26fd35df4f0cd77019243c858/app/helpers/namespaces_helper.rb#L86). | `Boolean`            | `true`                   |
| `settings_path_helper` | Lambda function that generates a path to the ancestor setting. For example, `-> (locked_ancestor) { edit_group_path(locked_ancestor, anchor: 'js-permissions-settings') }`                                           | `Lambda`             | `true`                   |
| `help_text`            | Text shown below the checkbox.                                                                                                                                                                                       | `String`             | `false` (`nil`)          |

[`_lock_tooltips.html.haml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/views/shared/namespaces/cascading_settings/_lock_tooltips.html.haml)

Renders the mount element needed to initialize the JavaScript used to display the tooltip when hovering over the lock icon. This partial is only needed once per page.

### JavaScript

[`initCascadingSettingsLockTooltips`](https://gitlab.com/gitlab-org/gitlab/-/blob/acb2ef4dbbd06f93615e8e6a1c0a78e7ebe20441/app/assets/javascripts/namespaces/cascading_settings/index.js#L4)

Initializes the JavaScript needed to display the tooltip when hovering over the lock icon (**{lock}**).
This function should be imported and called in the [page-specific JavaScript](fe_guide/performance.md#page-specific-javascript).

### Put it all together

```haml
-# app/views/groups/edit.html.haml

= render 'shared/namespaces/cascading_settings/lock_tooltips'

- delayed_project_removal_locked = cascading_namespace_setting_locked?(:delayed_project_removal, @group)
- merge_method_locked = cascading_namespace_setting_locked?(:merge_method, @group)

= form_for @group do |f|
  .form-group{ data: { testid: 'delayed-project-removal-form-group' } }
    = render 'shared/namespaces/cascading_settings/setting_checkbox', attribute: :delayed_project_removal,
        group: @group,
        form: f,
        setting_locked: delayed_project_removal_locked,
        settings_path_helper: -> (locked_ancestor) { edit_group_path(locked_ancestor, anchor: 'js-permissions-settings') },
        help_text: s_('Settings|Projects will be permanently deleted after a 7-day delay. Inherited by subgroups.') do
      = s_('Settings|Enable delayed project deletion')
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
      = f.gitlab_ui_radio_component :merge_method, :merge, s_('Settings|Merge commit'), help_text: s_('Settings|Every merge creates a merge commit.'), radio_options: { disabled: merge_method_locked }

    .gl-form-radio.custom-control.custom-radio
      = f.gitlab_ui_radio_component :merge_method, :rebase_merge, s_('Settings|Merge commit with semi-linear history'), help_text: s_('Settings|Every merge creates a merge commit.'), radio_options: { disabled: merge_method_locked }

    .gl-form-radio.custom-control.custom-radio
      = f.gitlab_ui_radio_component :merge_method, :ff, s_('Settings|Fast-forward merge'), help_text: s_('Settings|No merge commits are created.'), radio_options: { disabled: merge_method_locked }

    = render 'shared/namespaces/cascading_settings/enforcement_checkbox',
      attribute: :merge_method,
      group: @group,
      form: f,
      setting_locked: merge_method_locked
```

```javascript
// app/assets/javascripts/pages/groups/edit/index.js

import { initCascadingSettingsLockTooltips } from '~/namespaces/cascading_settings';

initCascadingSettingsLockTooltips();
```

### Vue

[`cascading_lock_icon.vue`](https://gitlab.com/gitlab-org/gitlab/-/blob/acb2ef4dbbd06f93615e8e6a1c0a78e7ebe20441/app/assets/javascripts/namespaces/cascading_settings/components/cascading_lock_icon.vue)

| Local                  | Description                                                                                                                                                                                                          | Type                 | Required (default value) |
|:-----------------------|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|:---------------------|:-------------------------|
| `ancestorNamespace`            | The namespace for associated group's ancestor.                                                                                                                                                        | `Object` | `false` (`null`)                  |
| `isLockedByApplicationSettings`            | Boolean for if the cascading variable `locked_by_application_settings` is set or not on the instance.                                                                                                                                                        | `Boolean` | `true`                   |
| `isLockedByGroupAncestor`            | Boolean for if the cascading variable `locked_by_ancestor` is set or not for a group.                                                                                                                                                        | `Boolean` | `true`                   |

### Using Vue

 1. In the your Ruby helper, you will need to call the following to send do your Vue component. Be sure to switch out `:replace_attribute_here` with your cascading attribute.

 ```ruby
 # Example call from your Ruby helper  method for groups
 cascading_settings_data = cascading_namespace_settings_tooltip_data(:replace_attribute_here, @group, method(:edit_group_path))[:tooltip_data]
 ```

 ```ruby
 # Example call from your Ruby helper  method for projects
cascading_settings_data = project_cascading_namespace_settings_tooltip_data(:duo_features_enabled, project, method(:edit_group_path)).to_json
 ```

1. From your Vue's `index.js` file, be sure to convert the data into JSON and camel case format. This will make it easier to use in Vue.

```javascript
let cascadingSettingsDataParsed;
try {
  cascadingSettingsDataParsed = convertObjectPropsToCamelCase(JSON.parse(cascadingSettingsData), {
    deep: true,
  });
} catch {
  cascadingSettingsDataParsed = null;
}
```

1. From your Vue component, either `provide/inject` or pass your `cascadingSettingsDataParsed` variable to the component. You will also want to have a helper method to not show the `cascading-lock-icon` component if the cascading data returned is either null or an empty object.

```vue
// ./ee/my_component.vue

<script>
export default {
  computed: {
    showCascadingIcon() {
      return (
        this.cascadingSettingsData &&
        Object.keys(this.cascadingSettingsData).length
      );
    },
  },
}
</script>

<template>
  <cascading-lock-icon
    v-if="showCascadingIcon"
    :is-locked-by-group-ancestor="cascadingSettingsData.lockedByAncestor"
    :is-locked-by-application-settings="cascadingSettingsData.lockedByApplicationSetting"
    :ancestor-namespace="cascadingSettingsData.ancestorNamespace"
    class="gl-ml-1"
  />
</template>
```

You can look into the following examples of MRs for implementing `cascading_lock_icon.vue` into other Vue components:

- [Add cascading settings in Groups](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/162101)
- [Add cascading settings in Projects](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163050)

### Reasoning for supporting both HAML and Vue

It is the goal to build all new frontend features in Vue and to eventually move away from building features in HAML. However there are still HAML frontend features that utilize cascading settings, so support will remain with `initCascadingSettingsLockTooltips` until those components have been migrated into Vue.
