---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Import project from repository by URL
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can import your existing repositories by providing the Git URL. You can't import GitLab issues and merge requests
this way. Other methods provide more complete import methods.

If the repository is too large, the import might time out.

You can import your Git repository by:

- [Using the UI](#import-a-project-by-using-the-ui)
- [Using the API](#import-a-project-by-using-the-api)

## Prerequisites

{{< history >}}

- Requirement for Maintainer role instead of Developer role introduced in GitLab 16.0 and backported to GitLab 15.11.1 and GitLab 15.10.5.

{{< /history >}}

- [Repository by URL import source](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources)
  must be enabled. If not enabled, ask your GitLab administrator to enable it. The Repository by URL import source is enabled
  by default on GitLab.com.
- At least the Maintainer role on the destination group to import to.
- If importing a private repository, an access token for authenticated access to the source repository might be required
  instead of a password.

## Import a project by using the UI

1. On the left sidebar, at the top, select **Create new** ({{< icon name="plus" >}}) and **New project/repository**.
1. Select **Import project**.
1. Select **Repository by URL**.
1. Enter a **Git repository URL**.
1. Complete the remaining fields. A username and password (or access token) is required for imports from private
   repositories.
1. Select **Create project**.

Your newly created project is displayed.

### Import a timed-out project

Imports of large repositories might time out after three hours.
To import a timed-out project:

1. Clone the repository.

   ```shell
   git clone --mirror https://example.com/group/project.git
   ```

   The `--mirror` option ensures all branches, tags, and refs are copied.

1. Add the new remote repository.

   ```shell
   cd repository.git
   git remote add new-origin https://gitlab.com/group/project.git
   ```

1. Push everything to the new remote repository.

   ```shell
   git push --mirror new-origin
   ```

## Import a project by using the API

You can use the [Projects API](../../../api/projects.md#create-a-project) to import a Git repository:

```shell
curl --location "https://gitlab.example.com/api/v4/projects/" \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer <your-token>' \
--data-raw '{
    "description": "New project description",
    "path": "new_project_path",
    "import_url": "https://username:password@example.com/group/project.git"
}'
```

Some providers do not allow a password and instead require an access token.
