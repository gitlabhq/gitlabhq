---
type: reference, howto
stage: Manage
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Migrate groups from another instance of GitLab **(FREE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/249160) in GitLab 13.7 [with a flag](../../feature_flags.md) named `bulk_import`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/338985) in GitLab 14.3.

NOTE:
The importer migrates **only** the group data listed on this page. To leave feedback on this
feature, see [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/284495).

Using GitLab Group Migration, you can migrate existing top-level groups from GitLab.com or a self-managed instance. Groups can be migrated to a target instance, as a top-level group, or as a subgroup of any existing top-level group.

The following resources are migrated to the target instance:

- Groups ([Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4374) in 13.7)
  - description
  - attributes
  - subgroups
  - avatar ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/322904) in 14.0)
- Group Labels ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/292429) in 13.9)
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

Any other items are **not** migrated.

## Enable or disable GitLab Group Migration

GitLab Migration is deployed behind the `bulk_import` feature flag, which is **enabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../../administration/feature_flags.md)
can disable it.

To disable it:

```ruby
Feature.disable(:bulk_import)
```

To enable it:

```ruby
Feature.enable(:bulk_import)
```

## Import your groups into GitLab

Before you begin, ensure that the target instance of GitLab can communicate with the source
over HTTPS (HTTP is not supported).

NOTE:
This might involve reconfiguring your firewall to prevent blocking connection on the side of self-managed instance.

### Connect to the remote GitLab instance

1. Go to the New Group page:

   - On the top bar, select `+` and then **New group**.
   - Or, on an existing group's page, in the top right, select **New subgroup**.

   ![Navigation paths to create a new group](img/new_group_navigation_v13_8.png)

1. On the New Group page, select **Import group**.

   ![Fill in import details](img/import_panel_v14_1.png)

1. Enter the source URL of your GitLab instance.
1. Generate or copy a [personal access token](../../../user/profile/personal_access_tokens.md)
   with the `api` and `read_repository` scopes on your remote GitLab instance.
1. Enter the [personal access token](../../../user/profile/personal_access_tokens.md) for your remote GitLab instance.
1. Select **Connect instance**.

### Selecting which groups to import

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
