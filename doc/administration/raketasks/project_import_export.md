---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Project import/export administration **(FREE SELF)**

GitLab provides Rake tasks relating to project import and export. For more information, see:

- [Project import/export documentation](../../user/project/settings/import_export.md).
- [Project import/export API](../../api/project_import_export.md).
- [Developer documentation: project import/export](../../development/import_export.md)

## Project import status

You can query an import through the [Project import/export API](../../api/project_import_export.md#import-status).
As described in the API documentation, the query may return an import error or exceptions.

## Import/export Rake tasks

The GitLab import/export version can be checked by using the following command:

```shell
# Omnibus installations
sudo gitlab-rake gitlab:import_export:version

# Installations from source
bundle exec rake gitlab:import_export:version RAILS_ENV=production
```

The current list of DB tables to export can be listed by using the following command:

```shell
# Omnibus installations
sudo gitlab-rake gitlab:import_export:data

# Installations from source
bundle exec rake gitlab:import_export:data RAILS_ENV=production
```

Note the following:

- Importing is only possible if the version of the import and export GitLab instances are
  compatible as described in the [Version history](../../user/project/settings/import_export.md#version-history).
- The project import option must be enabled:

  1. On the top bar, select **Menu > Admin**.
  1. On the left sidebar, select **Settings > General**.
  1. Expand **Visibility and access controls**.
  1. Under **Import sources**, check the "Project export enabled" option.
  1. Select **Save changes**.

- The exports are stored in a temporary directory and are deleted every
  24 hours by a specific worker.

### Import large projects using a Rake task

If you have a larger project, consider using a Rake task as described in our [developer documentation](../../development/import_project.md#importing-via-a-rake-task).

### Export using a Rake task

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/25598) in GitLab 12.9.

You can use a Rake task to export large project.

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `username`      | string | yes | User name |
| `namespace_path` | string | yes | Namespace path |
| `project_path` | string | yes | Project name |
| `archive_path` | string | yes | Path to file to store the export project tarball |

```shell
gitlab-rake "gitlab:import_export:export[username, namespace_path, project_path, archive_path]"
```

## Troubleshooting

If you are having trouble with import/export, you can enable debug mode using the same Rake task:

```shell
# Import
IMPORT_DEBUG=true gitlab-rake "gitlab:import_export:import[root, group/subgroup, testingprojectimport, /path/to/file_to_import.tar.gz]"

# Export
EXPORT_DEBUG=true gitlab-rake "gitlab:import_export:export[root, group/subgroup, projectnametoexport, /tmp/export_file.tar.gz]"
```
