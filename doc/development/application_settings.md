---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Application settings development

This document provides a development guide for contributors to add application
settings to GitLab.

Application settings are stored in the `application_settings` table. Each setting has its own column and there should only be one row.

## Add a new application setting

First of all, you have to decide if it is necessary to add an application setting.
Consider our [configuration principles](https://handbook.gitlab.com/handbook/product/product-principles/#configuration-principles) when adding a new setting.

We prefer saving the related application settings in a single JSONB column to avoid making the `application_settings`
table wider. Also, adding a new setting to an existing column won't require a database review so it saves time.

To add a new setting, you have to:

- Check if there is an existing JSONB column that you can use to store the new setting.
- If there is an existing JSON column then:
  - Add new setting to the JSONB column like [rate_limits](https://gitlab.com/gitlab-org/gitlab/-/blob/63b37287ae028842fcdcf56d311e6bb0c7e09e79/app/models/application_setting.rb#L603)
    in the `ApplicationSetting` model.
  - Update the JSON schema validator for the column like [rate_limits validator](https://gitlab.com/gitlab-org/gitlab/-/blob/63b37287ae028842fcdcf56d311e6bb0c7e09e79/app/validators/json_schemas/application_setting_rate_limits.json).
- If there isn't an existing JSON column which you can use then:
  - Add a new JSON column to the `application_settings` table to store, see this [merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140633/diffs) for reference.
  - Add a constraint to ensure the column always stores a hash, see this [merge request](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141765/diffs) for reference.
  - Create follow-up issues to move existing related columns to this newly created JSONB column.
- Add the new setting to the [list of visible attributes](https://gitlab.com/gitlab-org/gitlab/-/blob/6f33ad46ffeac454c6c9ce92d6ba328a72f062fd/app/helpers/application_settings_helper.rb#L215).
- Add the new setting to it to [`ApplicationSettingImplementation#defaults`](https://gitlab.com/gitlab-org/gitlab/-/blob/6f33ad46ffeac454c6c9ce92d6ba328a72f062fd/app/models/application_setting_implementation.rb#L36), if the setting has a default value.
- Add a [test for the default value](https://gitlab.com/gitlab-org/gitlab/-/blob/6f33ad46ffeac454c6c9ce92d6ba328a72f062fd/spec/models/application_setting_spec.rb#L20), if the setting has a default value.
- Add a validation for the new field to the [`ApplicationSetting` model](https://gitlab.com/gitlab-org/gitlab/-/blob/6f33ad46ffeac454c6c9ce92d6ba328a72f062fd/app/models/application_setting.rb).
- Add a [model test](https://gitlab.com/gitlab-org/gitlab/-/blob/6f33ad46ffeac454c6c9ce92d6ba328a72f062fd/spec/models/application_setting_spec.rb) for the validation and default value
- Find the [right view file](https://gitlab.com/gitlab-org/gitlab/-/tree/26ad8f4086c03283814bda50ff6e7043902cdbff/app/views/admin/application_settings) or create a new one and add a form field to the new setting.
- Update the [API documentation](https://gitlab.com/gitlab-org/gitlab/-/blob/6f33ad46ffeac454c6c9ce92d6ba328a72f062fd/doc/api/settings.md). Application settings will automatically be available on the REST API.
- Run the `scripts/cells/application-settings-analysis.rb` script to generate a definition YAML file at `config/application_setting_columns/*.yml` and update the documentation file at
  [`cells/application_settings_analysis`](cells/application_settings_analysis.md), based on `db/structure.sql` as well as the API documentation. Once the definition file is created, please ensure you set the
  `clusterwide` key to `true` or `false` in it. Setting `clusterwide: true` means that the attribute value will be copied from the leader cell to other cells
  [in the context of Cells architecture](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/cells/impacted_features/admin-area/). In most cases, `clusterwide: false` is preferrable.

### Database migration example

```ruby
class AddNewSetting < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :application_settings, :new_setting, :text, if_not_exists: true
    end

    add_text_limit :application_settings, :new_setting, 255
  end

  def down
    with_lock_retries do
      remove_column :application_settings, :new_setting, if_exists: true
    end
  end
end
```

### Model validation example

```ruby
validates :new_setting,
          length: { maximum: 255, message: N_('is too long (maximum is %{count} characters)') },
          allow_blank: true
```
