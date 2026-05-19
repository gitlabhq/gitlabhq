---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrate through a manifest file
description: "Import repositories to GitLab by using manifest files."
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Import Git repositories based on a manifest file like the one used by the
[Android repository](https://android.googlesource.com/platform/manifest/+/6dc9af1b583e5c6a4ab9c38e3f5646efd8079b7d/default.xml).
Use the manifest to import a project with many repositories like the Android Open Source Project (AOSP).

## Prerequisites

{{< history >}}

- Requirement for Maintainer role instead of Developer role introduced in GitLab 16.0 and backported to GitLab 15.11.1 and GitLab 15.10.5.

{{< /history >}}

- [Manifest import source](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)
  enabled. If not enabled, ask your GitLab administrator to enable it. The Manifest import source is enabled
  by default on GitLab.com.
- The Maintainer or Owner role on the destination top-level group to import to. You might want to create a new top-level
  group for the import.

## Manifest file format

The manifest file must be an XML file up to 1 MB in size. The file must have:

- One `remote` tag with a `review` attribute that contains a URL to a Git server.
- `project` tags with a `name` and `path` attribute.

GitLab builds the URL to the repository by combining the URL from the `remote` tag with a project name.
The path attribute is used to represent the project path in GitLab.

For example:

```xml
<manifest>
  <remote review="https://android.googlesource.com/" />

  <project path="build/make" name="platform/build" />
  <project path="build/blueprint" name="platform/build/blueprint" />
</manifest>
```

In this example, GitLab creates the following projects:

| GitLab                                            | Import URL |
|:--------------------------------------------------|:-----------|
| `https://gitlab.com/<group_name>/build/make`      | <https://android.googlesource.com/platform/build> |
| `https://gitlab.com/<group_name>/build/blueprint` | <https://android.googlesource.com/platform/build/blueprint> |

## Import the repositories

To import repositories by using a manifest file:

1. In the upper-right corner, select **Create new** ({{< icon name="plus" >}}) and **New project/repository**.
1. Select **Import project**.
1. Select **Manifest file**.
1. Select a group you want to import to.
1. Choose an XML-formatted manifest file to use.
1. Select **List available repositories**. You are redirected to the import status page with a projects list based on
   the manifest file.
1. To import:
   - All projects for the first time, select **Import all repositories**.
   - Individual projects again, select **Re-import**. Specify a new name and select **Re-import** again. Re-importing
     creates a new copy of the source project.

## Related topics

- [Import and export settings](../../../administration/settings/import_and_export_settings.md).
- [Sidekiq configuration for imports](../../../administration/sidekiq/configuration_for_imports.md).
- [Running multiple Sidekiq processes](../../../administration/sidekiq/extra_sidekiq_processes.md).
- [Processing specific job classes](../../../administration/sidekiq/processing_specific_job_classes.md).
