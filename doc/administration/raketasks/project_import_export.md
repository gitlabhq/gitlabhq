---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Project import and export Rake tasks
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab provides Rake tasks for [project import and export](../../user/project/settings/import_export.md).

You can only import from a [compatible](../../user/project/settings/import_export.md#compatibility) GitLab instance.

## Import large projects

The [Rake task](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/tasks/gitlab/import_export/import.rake) is used for importing large GitLab project exports.

As part of this task, we also disable direct upload. This avoids uploading a huge archive to GCS, which can cause idle transaction timeouts.

We can run this task from the terminal:

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `username`      | string | yes | User name |
| `namespace_path` | string | yes | Namespace path |
| `project_path` | string | yes | Project path |
| `archive_path` | string | yes | Path to the exported project tarball you want to import |

::Tabs

:::TabTitle Linux package (Omnibus)

```shell
gitlab-rake "gitlab:import_export:import[root, group/subgroup, testingprojectimport, /path/to/file.tar.gz]"
```

:::TabTitle Self-compiled (source)

```shell
bundle exec rake "gitlab:import_export:import[root, group/subgroup, testingprojectimport, /path/to/file.tar.gz]" RAILS_ENV=production
```

::EndTabs

## Export large projects

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
