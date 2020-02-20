# Project import/export administration **(CORE ONLY)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/3050) in GitLab 8.9.
> - From GitLab 11.3, import/export can use object storage automatically.

See also:

- [Project import/export documentation](../../user/project/settings/import_export.md).
- [Project import/export API](../../api/project_import_export.md).

The GitLab import/export version can be checked by using the following command:

```shell
# Omnibus installations
sudo gitlab-rake gitlab:import_export:version

# Installations from source
bundle exec rake gitlab:import_export:version RAILS_ENV=production
```

The current list of DB tables that will be exported can be listed by using the following command:

```shell
# Omnibus installations
sudo gitlab-rake gitlab:import_export:data

# Installations from source
bundle exec rake gitlab:import_export:data RAILS_ENV=production
```

## Important notes

Note the following:

- Importing is only possible if the version of the import and export GitLab instances are
  compatible as described in the [Version history](../../user/project/settings/import_export.md#version-history).
- The project import option must be enabled in
  application settings (`/admin/application_settings/general`) under **Import sources**, which is available
  under **{admin}** **Admin Area >** **{settings}** **Settings > Visibility and access controls**.
- The exports are stored in a temporary [shared directory](../../development/shared_files.md)
  and are deleted every 24 hours by a specific worker.
