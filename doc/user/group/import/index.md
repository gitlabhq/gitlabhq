---
type: reference, howto
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Migrate groups from another instance of GitLab **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/249160) in GitLab 13.7 [with a flag](../../feature_flags.md) named `bulk_import`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/338985) in GitLab 14.3.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature, ask an administrator to [disable the feature flag](../../../administration/feature_flags.md) named `bulk_import`. On GitLab.com, this feature is available.

You can migrate your existing top-level groups to any of the following:

- Another GitLab instance, including GitLab.com.
- Another top-level group.
- The subgroup of any existing top-level group.

Migrating groups is not the same as [group import/export](../settings/import_export.md).

- Group import/export requires you to export a group to a file and then import that file in
  another GitLab instance.
- Group migration automates this process.

## Import your groups into GitLab

When you migrate a group, you connect to your GitLab instance and then choose
groups to import. Not all the data is migrated. View the
[Migrated resources](#migrated-resources) list for details.

Leave feedback about group migration in [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/284495).

NOTE:
You might need to reconfigure your firewall to prevent blocking the connection on the self-managed
instance.

### Connect to the remote GitLab instance

Before you begin, ensure that the target GitLab instance can communicate with the source over HTTPS
(HTTP is not supported). You might need to reconfigure your firewall to prevent blocking the connection on the self-managed
instance.

Then create the group you want to import into, and connect:

1. Create a new group or subgroup:

   - On the top bar, select `+` and then **New group**.
   - Or, on an existing group's page, in the top right, select **New subgroup**.

1. Select **Import group**.
1. Enter the source URL of your GitLab instance.
1. Generate or copy a [personal access token](../../../user/profile/personal_access_tokens.md)
   with the `api` and `read_repository` scopes on your remote GitLab instance.
1. Enter the [personal access token](../../../user/profile/personal_access_tokens.md) for your remote GitLab instance.
1. Select **Connect instance**.

### Select the groups to import

After you have authorized access to the GitLab instance, you are redirected to the GitLab Group
Migration importer page. The remote groups you have the Owner role for are listed.

1. By default, the proposed group namespaces match the names as they exist in remote instance, but based on your permissions, you can choose to edit these names before you proceed to import any of them.
1. Next to the groups you want to import, select **Import**.
1. The **Status** column shows the import status of each group. If you leave the page open, it updates in real-time.
1. After a group has been imported, select its GitLab path to open its GitLab URL.

![Group Importer page](img/bulk_imports_v14_1.png)

## Automate group and project import **(PREMIUM)**

For information on automating user, group, and project import API calls, see
[Automate group and project import](../../project/import/index.md#automate-group-and-project-import).

## Migrated resources

Only the following resources are migrated to the target instance. Any other items are **not**
migrated:

- Groups ([Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4374) in 13.7)
  - description
  - attributes
  - subgroups
  - avatar ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/322904) in 14.0)
- Group labels ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/292429) in 13.9)
  - title
  - description
  - color
  - created_at ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/300007) in 13.10)
  - updated_at ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/300007) in 13.10)
- Members ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/299415) in 13.9)
  Group members are associated with the imported group if:
  - The user already exists in the target GitLab instance and
  - The user has a public email in the source GitLab instance that matches a
    confirmed email in the target GitLab instance
- Epics ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/250281) in 13.7)
  - title
  - description
  - state (open / closed)
  - start date
  - due date
  - epic order on boards
  - confidentiality
  - labels ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/297460) in 13.9)
  - author ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/298745) in 13.9)
  - parent epic ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/297459) in 13.9)
  - emoji award ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/297466) in 13.9)
  - events ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/297465) in 13.10)
- Milestones ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/292427) in 13.10)
  - title
  - description
  - state (active / closed)
  - start date
  - due date
  - created at
  - updated at
  - iid ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/326157) in 13.11)
- Iterations ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/292428) in 13.10)
  - iid
  - title
  - description
  - state (upcoming / started / closed)
  - start date
  - due date
  - created at
  - updated at
- Badges ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/292431) in 13.11)
  - name
  - link URL
  - image URL
- Boards
- Board Lists

## Troubleshooting Group Migration

In a [rails console session](../../../administration/operations/rails_console.md#starting-a-rails-console-session),
you can find the failure or error messages for the group import attempt using:

```shell
# Get relevant import records
import = BulkImports::Entity.where(namespace_id: Group.id).bulk_import

# Alternative lookup by user
import = BulkImport.where(user_id: User.find(...)).last

# Get list of import entities. Each entity represents either a group or a project
entities = import.entities

# Get a list of entity failures
entities.map(&:failures).flatten

# Alternative failure lookup by status
entities.where(status: [-1]).pluck(:destination_name, :destination_namespace, :status)
```
