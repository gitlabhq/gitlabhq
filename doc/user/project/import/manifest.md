---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Import multiple repositories by uploading a manifest file
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - Ability to re-import projects [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23905) in GitLab 15.9.

GitLab allows you to import all the required Git repositories
based on a manifest file like the one used by the
[Android repository](https://android.googlesource.com/platform/manifest/+/2d6f081a3b05d8ef7a2b1b52b0d536b2b74feab4/default.xml).
Use the manifest to import a project with many
repositories like the Android Open Source Project (AOSP).

## Prerequisites

> - Requirement for Maintainer role instead of Developer role introduced in GitLab 16.0 and backported to GitLab 15.11.1 and GitLab 15.10.5.

- [Manifest import source](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)
  must be enabled. If not enabled, ask your GitLab administrator to enable it. The Manifest import source is enabled
  by default on GitLab.com.
- GitLab must use PostgreSQL for its database, because [subgroups](../../group/subgroups/_index.md) are needed for the manifest import
  to work. Read more about the [database requirements](../../../install/requirements.md#postgresql).
- At least the Maintainer role on the destination group to import to.

## Manifest format

A manifest must be an XML file up to 1 MB in size. There must be one `remote` tag with a `review`
attribute that contains a URL to a Git server, and each `project` tag must have
a `name` and `path` attribute. GitLab then builds the URL to the repository
by combining the URL from the `remote` tag with a project name.
A path attribute is used to represent the project path in GitLab.

Below is a valid example of a manifest file:

```xml
<manifest>
  <remote review="https://android.googlesource.com/" />

  <project path="build/make" name="platform/build" />
  <project path="build/blueprint" name="platform/build/blueprint" />
</manifest>
```

As a result, the following projects are created:

| GitLab                                          | Import URL                                                  |
|:------------------------------------------------|:------------------------------------------------------------|
| `https://gitlab.com/YOUR_GROUP/build/make`      | <https://android.googlesource.com/platform/build>           |
| `https://gitlab.com/YOUR_GROUP/build/blueprint` | <https://android.googlesource.com/platform/build/blueprint> |

## Import the repositories

To start the import:

1. From your GitLab dashboard select **New project**.
1. Switch to the **Import project** tab.
1. Select **Manifest file**.
1. Provide GitLab with a manifest XML file.
1. Select a group you want to import to (you need to create a group first if you don't have one).
1. Select **List available repositories**. At this point, you are redirected
   to the import status page with projects list based on the manifest file.
1. To import:
   - All projects for the first time: Select **Import all repositories**.
   - Individual projects again: Select **Re-import**. Specify a new name and select **Re-import** again. Re-importing creates a new copy of the source project.
