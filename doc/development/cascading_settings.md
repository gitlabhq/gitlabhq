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
- `delayed_project_removal_locked_ancestor` - (Returns locked namespace settings object [namespace_id])

The attribute reader method (`delayed_project_removal`) returns the correct
cascaded value using the following criteria:

1. Returns the dirty value, if the attribute has changed. This allows standard
   Rails validators to be used on the attribute, though `nil` values *must* be allowed. 
1. Return locked ancestor value.
1. Return locked instance-level application settings value.
1. Return this namespace's attribute, if not nil.
1. Return value from nearest ancestor where value is not nil.
1. Return instance-level application setting.
