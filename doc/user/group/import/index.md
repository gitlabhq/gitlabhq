---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Migrating GitLab groups **(FREE)**

You can migrate GitLab groups:

- From self-managed GitLab to GitLab.com.
- From GitLab.com to self-managed GitLab.
- From one self-managed GitLab instance to another.
- Between groups in the same GitLab instance.

You can migrate groups in two ways:

- By direct transfer (recommended).
- By uploading an export file.

If you migrate from GitLab.com to self-managed GitLab, an administrator can create users on the self-managed GitLab instance.

## Migrate groups by direct transfer (recommended)

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/249160) in GitLab 13.7 for group resources [with a flag](../../feature_flags.md) named `bulk_import`. Disabled by default.
> - Group items [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/338985) in GitLab 14.3.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267945) in GitLab 14.4 for project resources [with a flag](../../feature_flags.md) named `bulk_import_projects`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/339941) in GitLab 15.6.
> - New application setting `bulk_import_enabled` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/383268) in GitLab 15.8. `bulk_import` feature flag removed.
> - `bulk_import_projects` feature flag [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/339941) in GitLab 15.10.

On self-managed GitLab, by default [migrating group items](#migrated-group-items) is not available. To show the
feature, ask an administrator to [enable it in application settings](../../admin_area/settings/visibility_and_access_controls.md#enable-migration-of-groups-and-projects-by-direct-transfer).

Migrating groups by direct transfer copies the groups from one place to another. You can:

- Copy many groups at once.
- In the GitLab UI, copy top-level groups to:
  - Another top-level group.
  - The subgroup of any existing top-level group.
  - Another GitLab instance, including GitLab.com.
- In the [API](../../../api/bulk_imports.md), copy top-level groups and subgroups to these locations.
- Copy groups with projects (in [Beta](../../../policy/alpha-beta-support.md#beta) and not ready for production
  use) or without projects. Copying projects with groups is available:
  - On GitLab.com by default.

Not all group and project resources are copied. See list of copied resources below:

- [Migrated group items](#migrated-group-items).
- [Migrated project items](#migrated-project-items-beta).

WARNING:
Importing groups with projects is in [Beta](../../../policy/alpha-beta-support.md#beta). This feature is not
ready for production use.

We invite you to leave your feedback about migrating by direct transfer in
[the feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/284495).

If you want to move groups instead of copying groups, you can [transfer groups](../manage.md#transfer-a-group) if the
groups are in the same GitLab instance. Transferring groups is a faster and more complete option.

### Known issues

See [epic 6629](https://gitlab.com/groups/gitlab-org/-/epics/6629) for a list of known issues for migrating by direct
transfer.

### Limits

| Limit       | Description                                                                                                                                                                     |
|:------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 6           | Maximum number of migrations permitted by a destination GitLab instance per minute per user. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/386452) in GitLab 15.9. |
| 5 GB        | Maximum relation size that can be downloaded from the source instance.                                                                                                          |
| 10 GB       | Maximum size of a decompressed archive.                                                                                                                                         |
| 210 seconds | Maximum number of seconds to wait for decompressing an archive file.                                                                                                            |
| 50 MB       | Maximum length an NDJSON row can have.                                                                                                                                          |
| 5 minutes   | Maximum number of seconds until an empty export status on source instance is raised.                                                                                            |
| 8 hours     | Time until migration times out.                                                                                                                                                 |
| 90 minutes  | Time the destination is waiting for export to complete.                                                                                                                         |

### Visibility rules

After migration:

- Private groups and projects stay private.
- Public groups and projects:
  - Stay public when copied into a public group.
  - Become private when copied into a private group.

If used a private network on your source instance to hide content from the general public,
make sure to have a similar setup on the destination instance, or to import into a private group.

### Prerequisites

> Requirement for Maintainer role instead of Developer role introduced in GitLab 16.0 and backported to GitLab 15.11.1 and GitLab 15.10.5.

To migrate groups by direct transfer:

- The network connection between instances or GitLab.com must support HTTPS.
- Any firewalls must not block the connection between the source and destination GitLab instances.
- Both GitLab instances must have group migration by direct transfer
  [enabled in application settings](../../admin_area/settings/visibility_and_access_controls.md#enable-migration-of-groups-and-projects-by-direct-transfer)
  by an instance administrator.
- The source GitLab instance must be running GitLab 14.0 or later.
- You must have a [personal access token](../../../user/profile/personal_access_tokens.md) for the source GitLab
  instance:
  - For GitLab 15.1 and later source instances, the personal access token must have the `api` scope.
  - For GitLab 15.0 and earlier source instances, the personal access token must have both the `api` and
    `read_repository` scopes.
- You must have the Owner role on the source group to migrate from.
- You must have at least the Maintainer role on the destination group to migrate to.

### Prepare user accounts

To ensure GitLab maps users and their contributions correctly:

1. Create the required users on the destination GitLab instance. You can create users with the API only on self-managed instances because it requires
   administrator access. When migrating to GitLab.com or a self-managed GitLab instance you can:
   - Create users manually.
   - Set up or use your existing [SAML SSO provider](../saml_sso/index.md) and leverage user synchronization of SAML SSO groups supported through
     [SCIM](../../group/saml_sso/scim_setup.md). You can
     [bypass the GitLab user account verification with verified email domains](../saml_sso/index.md#bypass-user-email-confirmation-with-verified-domains).
1. Ensure that users have a [public email](../../profile/index.md#set-your-public-email) on the source GitLab instance that matches any confirmed email address on the destination GitLab instance. Most
   users receive an email asking them to confirm their email address.
1. If users already exist on the destination instance and you use [SAML SSO for GitLab.com groups](../../group/saml_sso/index.md), all users must
   [link their SAML identity to their GitLab.com account](../../group/saml_sso/index.md#link-saml-to-your-existing-gitlabcom-account).

### Connect the source GitLab instance

Create the group you want to import to and connect the source GitLab instance:

1. Create either:
   - A new group. On the top bar, select **{plus-square}**, then **New group**, and select **Import group**.
   - A new subgroup. On existing group's page, either:
     - Select **New subgroup**.
     - On the top bar, Select **{plus-square}** and then **New subgroup**. Then on the left sidebar, select the **import an existing group** link.
1. Enter the URL of a GitLab instance running GitLab 14.0 or later.
1. Enter the [personal access token](../../../user/profile/personal_access_tokens.md) for your source GitLab instance.
1. Select **Connect instance**.

### Select the groups and projects to import

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/385689) in GitLab 15.8, option to import groups with or without projects.

After you have authorized access to the source GitLab instance, you are redirected to the GitLab group
importer page. Here you can see a list of the top-level groups on the connected source instance where you have the Owner
role.

1. By default, the proposed group namespaces match the names as they exist in source instance, but based on your permissions, you can choose to edit these names before you proceed to import any of them.
1. Next to the groups you want to import, select either:
   - **Import with projects**.
   - **Import without projects**.
1. The **Status** column shows the import status of each group. If you leave the page open, it updates in real-time.
1. After a group has been imported, select its GitLab path to open its GitLab URL.

WARNING:
Importing groups with projects is in [Beta](../../../policy/alpha-beta-support.md#beta). This feature is not
ready for production use.

### Group import history

You can view all groups migrated by you by direct transfer listed on the group import history page. This list includes:

- Paths of source groups.
- Paths of destination groups.
- Start date of each import.
- Status of each import.
- Error details if any errors occurred.

To view group import history:

1. Sign in to GitLab.
1. On the top bar, select **Create new…** (**{plus-square}**).
1. Select **New group**.
1. Select **Import group**.
1. In the upper-right corner, select **History**.
1. If there are any errors for a particular import, you can see them by selecting **Details**.

### Migrated group items

The group items that are migrated depend on the version of GitLab you use on the destination. To determine if a
specific group item is migrated:

1. Check the [`groups/stage.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/bulk_imports/groups/stage.rb)
   file for all editions and the
   [`groups/stage.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ee/bulk_imports/groups/stage.rb) file
   for Enterprise Edition for your version on the destination. For example, for version 15.9:
   - <https://gitlab.com/gitlab-org/gitlab/-/blob/15-9-stable-ee/lib/bulk_imports/groups/stage.rb> (all editions).
   - <https://gitlab.com/gitlab-org/gitlab/-/blob/15-9-stable-ee/ee/lib/ee/bulk_imports/groups/stage.rb> (Enterprise
     Edition).
1. Check the
   [`group/import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/group/import_export.yml)
   file for groups for your version on the destination. For example, for version 15.9:
   <https://gitlab.com/gitlab-org/gitlab/-/blob/15-9-stable-ee/lib/gitlab/import_export/group/import_export.yml>.

Any other group items are **not** migrated.

Group items that are migrated to the destination GitLab instance include:

| Group item           | Introduced in                                                               |
|:---------------------|:----------------------------------------------------------------------------|
| Badges               | [GitLab 13.11](https://gitlab.com/gitlab-org/gitlab/-/issues/292431)        |
| Boards               | [GitLab 13.7](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18938)  |
| Board lists          | [GitLab 13.7](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/24863)  |
| Epics <sup>1</sup>   | [GitLab 13.7](https://gitlab.com/gitlab-org/gitlab/-/issues/250281)         |
| Group labels         | [GitLab 13.9](https://gitlab.com/gitlab-org/gitlab/-/issues/292429)         |
| Iterations           | [GitLab 13.10](https://gitlab.com/gitlab-org/gitlab/-/issues/292428)        |
| Iteration cadences   | [GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96570)  |
| Members <sup>2</sup> | [GitLab 13.9](https://gitlab.com/gitlab-org/gitlab/-/issues/299415)         |
| Group milestones     | [GitLab 13.10](https://gitlab.com/gitlab-org/gitlab/-/issues/292427)        |
| Namespace settings   | [GitLab 14.10](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85128) |
| Release milestones   | [GitLab 15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/339422)         |
| Subgroups            | [GitLab 13.7](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18938)  |
| Uploads              | [GitLab 13.7](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18938)  |

1. Epic resource state events [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4, label
   associations [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/62074) in GitLab 13.12, state and
   state ID [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28203) in GitLab 13.7, and system note
   metadata [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63551) in GitLab 14.0.
1. Group members are associated with the imported group if the user:
   - Already exists in the destination GitLab instance.
   - Has a public email in the source GitLab instance that matches a confirmed email in the destination GitLab instance.

### Migrated project items (Beta)

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267945) in GitLab 14.4 [with a flag](../../feature_flags.md) named `bulk_import_projects`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/339941) in GitLab 15.6.
> - `bulk_import_projects` feature flag [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/339941) in GitLab 15.10.
> - Project-only migrations using API [added](https://gitlab.com/gitlab-org/gitlab/-/issues/390515) in GitLab 15.11.

If you choose to migrate projects when you [select groups to migrate](#select-the-groups-and-projects-to-import),
project items are migrated with the projects.

The project items that are migrated depends on the version of GitLab you use on the destination. To determine if a
specific project item is migrated:

1. Check the [`projects/stage.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/bulk_imports/projects/stage.rb)
   file for all editions and the
   [`projects/stage.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/ee/bulk_imports/projects/stage.rb)
   file for Enterprise Edition for your version on the destination. For example, for version 15.9:
   - <https://gitlab.com/gitlab-org/gitlab/-/blob/15-9-stable-ee/lib/bulk_imports/projects/stage.rb> (all editions).
   - <https://gitlab.com/gitlab-org/gitlab/-/blob/15-9-stable-ee/ee/lib/ee/bulk_imports/projects/stage.rb> (Enterprise
     Edition).
1. Check the
   [`project/import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/project/import_export.yml)
   file for projects for your version on the destination. For example, for version 15.9:
   <https://gitlab.com/gitlab-org/gitlab/-/blob/15-9-stable-ee/lib/gitlab/import_export/project/import_export.yml>.

Any other project items are **not** migrated.

If you choose not to migrate projects along with groups or if you want to retry a project migration, you can
initiate project-only migrations using the [API](../../../api/bulk_imports.md).

WARNING:
Migrating projects when migrating groups by direct transfer is in [Beta](../../../policy/alpha-beta-support.md#beta)
and is not ready for production use.

Project items that are migrated to the destination GitLab instance include:

| Project item                            | Introduced in                                                              |
|:----------------------------------------|:---------------------------------------------------------------------------|
| Projects                                | [GitLab 14.4](https://gitlab.com/gitlab-org/gitlab/-/issues/267945)        |
| Auto DevOps                             | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/issues/339410)        |
| Badges                                  | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75029) |
| Branches (including protected branches) | [GitLab 14.7](https://gitlab.com/gitlab-org/gitlab/-/issues/339414)        |
| CI Pipelines                            | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/issues/339407)        |
| Commit comments                         | [GitLab 15.10](https://gitlab.com/gitlab-org/gitlab/-/issues/391601)       |
| Designs                                 | [GitLab 15.1](https://gitlab.com/gitlab-org/gitlab/-/issues/339421)        |
| Issues                                  | [GitLab 14.4](https://gitlab.com/gitlab-org/gitlab/-/issues/267946)        |
| Issue boards                            | [GitLab 14.4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71661) |
| Labels                                  | [GitLab 14.4](https://gitlab.com/gitlab-org/gitlab/-/issues/339419)        |
| LFS Objects                             | [GitLab 14.8](https://gitlab.com/gitlab-org/gitlab/-/issues/339405)        |
| Members                                 | [GitLab 14.8](https://gitlab.com/gitlab-org/gitlab/-/issues/341886)        |
| Merge requests                          | [GitLab 14.5](https://gitlab.com/gitlab-org/gitlab/-/issues/339403)        |
| Push rules                              | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/issues/339403)        |
| Milestones                              | [GitLab 14.5](https://gitlab.com/gitlab-org/gitlab/-/issues/339417)        |
| External pull requests                  | [GitLab 14.5](https://gitlab.com/gitlab-org/gitlab/-/issues/339409)        |
| Pipeline history                        | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/issues/339412)        |
| Pipeline schedules                      | [GitLab 14.8](https://gitlab.com/gitlab-org/gitlab/-/issues/339408)        |
| Project features                        | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/74722) |
| Releases                                | [GitLab 15.1](https://gitlab.com/gitlab-org/gitlab/-/issues/339422)        |
| Release evidences                       | [GitLab 15.1](https://gitlab.com/gitlab-org/gitlab/-/issues/360567)        |
| Repositories                            | [GitLab 14.4](https://gitlab.com/gitlab-org/gitlab/-/issues/267945)        |
| Snippets                                | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/issues/343438)        |
| Settings                                | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/issues/339416)        |
| Uploads                                 | [GitLab 14.5](https://gitlab.com/gitlab-org/gitlab/-/issues/339401)        |
| Wikis                                   | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/issues/345923)        |

#### Issue-related items

Issue-related project items that are migrated to the destination GitLab instance include:

| Issue-related project item      | Introduced in                                                              |
|:--------------------------------|:---------------------------------------------------------------------------|
| Issue iterations                | [GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96184) |
| Issue resource state events     | [GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/291983)        |
| Issue resource milestone events | [GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/291983)        |
| Issue resource iteration events | [GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/291983)        |
| Merge request URL references    | [GitLab 15.6](https://gitlab.com/gitlab-org/gitlab/-/issues/267947)        |
| Time tracking                   | [GitLab 14.4](https://gitlab.com/gitlab-org/gitlab/-/issues/267946)        |

#### Merge request-related items

Merge request-related project items that are migrated to the destination GitLab instance include:

| Merge request-related project item      | Introduced in                                                       |
|:----------------------------------------|:--------------------------------------------------------------------|
| Multiple merge request assignees        | [GitLab 15.3](https://gitlab.com/gitlab-org/gitlab/-/issues/339520) |
| Merge request reviewers                 | [GitLab 15.3](https://gitlab.com/gitlab-org/gitlab/-/issues/339520) |
| Merge request approvers                 | [GitLab 15.3](https://gitlab.com/gitlab-org/gitlab/-/issues/339520) |
| Merge request resource state events     | [GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) |
| Merge request resource milestone events | [GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) |
| Issue URL references                    | [GitLab 15.6](https://gitlab.com/gitlab-org/gitlab/-/issues/267947) |
| Time tracking                           | [GitLab 14.5](https://gitlab.com/gitlab-org/gitlab/-/issues/339403) |

#### Setting-related items

Setting-related project items that are migrated to the destination GitLab instance include:

| Setting-related project item | Introduced in                                                              |
|:-----------------------------|:---------------------------------------------------------------------------|
| Avatar                       | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75249) |
| Container expiration policy  | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75653) |
| Project properties           | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75898) |
| Service Desk                 | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75653) |

#### Excluded items

Project items excluded from migration because they contain sensitive information:

- Pipeline triggers.

### Troubleshooting

In a [rails console session](../../../administration/operations/rails_console.md#starting-a-rails-console-session),
you can find the failure or error messages for the group import attempt using:

```ruby
# Get relevant import records
import = BulkImports::Entity.where(namespace_id: Group.id).map(&:bulk_import).last

# Alternative lookup by user
import = BulkImport.where(user_id: User.find(...)).last

# Get list of import entities. Each entity represents either a group or a project
entities = import.entities

# Get a list of entity failures
entities.map(&:failures).flatten

# Alternative failure lookup by status
entities.where(status: [-1]).pluck(:destination_name, :destination_namespace, :status)
```

You can also see all migrated entities with any failures related to them using an
[API endpoint](../../../api/bulk_imports.md#list-all-group-or-project-migrations-entities).

#### Stale imports

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352985) in GitLab 14.10.

When troubleshooting group migration, an import may not complete because the import workers took
longer than 8 hours to execute. In this case, the `status` of either a `BulkImport` or
`BulkImport::Entity` is `3` (`timeout`):

```ruby
# Get relevant import records
import = BulkImports::Entity.where(namespace_id: Group.id).map(&:bulk_import)

import.status #=> 3 means that the import timed out.
```

#### Error: `404 Group Not Found`

If you attempt to import a group that has a path comprised of only numbers (for example, `5000`), GitLab attempts to
find the group by ID instead of the path. This causes a `404 Group Not Found` error in GitLab 15.4 and earlier.

To solve this, you must change the source group path to include a non-numerical character using either:

- The GitLab UI:

  1. On the top bar, select **Main menu > Groups** and find your group.
  1. On the left sidebar, select **Settings > General**.
  1. Expand **Advanced**.
  1. Under **Change group URL**, change the group URL to include non-numeric characters.

- The [Groups API](../../../api/groups.md#update-group).

#### Other `404` errors

You can receive other `404` errors when importing a group, for example:

```json
"exception_message": "Unsuccessful response 404 from [FILTERED] Bo...",
"exception_class": "BulkImports::NetworkError",
```

This error indicates a problem transferring from the _source_ instance. To solve this, check that you have met the [prerequisites](#prerequisites) on the source
instance.

## Migrate groups by uploading an export file (deprecated)

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/2888) in GitLab 13.0 as an experimental feature. May change in future releases.
> - [Deprecated](https://gitlab.com/groups/gitlab-org/-/epics/4619) in GitLab 14.6.

WARNING:
This feature was [deprecated](https://gitlab.com/groups/gitlab-org/-/epics/4619) in GitLab 14.6 and replaced by
[migrating groups by direct transfer](#migrate-groups-by-direct-transfer-recommended). However, this feature is still recommended for migrating groups between
offline systems. To follow progress on an alternative solution for [offline environments](../../application_security/offline_deployments/index.md), see
[the relevant epic](https://gitlab.com/groups/gitlab-org/-/epics/8985).

Prerequisites:

- Owner role on the group to migrate.

Using file exports, you can:

- Export any group to a file and upload that file to another GitLab instance or to another location on the same instance.
- Use either the GitLab UI or the [API](../../../api/group_import_export.md).
- Migrate groups one by one, then export and import each project for the groups one by one.

GitLab maps user contributions correctly when an admin access token is used to perform the import. GitLab does not map
user contributions correctly when you are importing from a self-managed instance to GitLab.com. Correct mapping of user
contributions when importing from a self-managed instance to GitLab.com can be preserved with paid involvement of
Professional Services team.

Note the following:

- Exports are stored in a temporary directory and are deleted every 24 hours by a specific worker.
- To preserve group-level relationships from imported projects, export and import groups first so that projects can
  be imported into the desired group structure.
- Imported groups are given a `private` visibility level, unless imported into a parent group.
- If imported into a parent group, a subgroup inherits the same level of visibility unless otherwise restricted.
- You can export groups from the [Community Edition to the Enterprise Edition](https://about.gitlab.com/install/ce-or-ee/)
  and vice versa. The Enterprise Edition retains some group data that isn't part of the Community Edition. If you're
  exporting a group from the Enterprise Edition to the Community Edition, you may lose this data. For more information,
  see [downgrading from EE to CE](../../../index.md).

### Compatibility

> Support for JSON-formatted project file exports [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/383682) in GitLab 15.8.

Group file exports are in NDJSON format.

You can import group file exports that were exported from a version of GitLab up to two
[minor](../../../policy/maintenance.md#versioning) versions behind, which is similar to our process for
[security releases](../../../policy/maintenance.md#security-releases).

For example:

| Destination version | Compatible source versions |
|:--------------------|:---------------------------|
| 13.0                | 13.0, 12.10, 12.9          |
| 13.1                | 13.1, 13.0, 12.10          |

### Exported contents

The [`import_export.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/import_export/group/import_export.yml)
file for groups lists items exported and imported when migrating groups using file exports. View this file in the branch
for your version of GitLab to check which items can be imported to the destination GitLab instance. For example,
[`import_export.yml` on the `14-10-stable-ee` branch](https://gitlab.com/gitlab-org/gitlab/-/blob/14-10-stable-ee/lib/gitlab/import_export/group/import_export.yml).

Group items that are exported include:

- Milestones
- Labels
- Boards and Board Lists
- Badges
- Subgroups (including all the aforementioned data)
- Epics
  - Epic resource state events ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4)
- Events
- [Wikis](../../project/wiki/group.md)
  ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/53247) in GitLab 13.9)
- Iterations cadences ([Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95372) in 15.4)

Items that are **not** exported include:

- Projects
- Runner tokens
- SAML discovery tokens

### Preparation

- To preserve the member list and their respective permissions on imported groups, review the users in these groups. Make
sure these users exist before importing the desired groups.
- Users must set a public email in the source GitLab instance that matches their confirmed primary email in the destination GitLab instance. Most users receive an email asking them to confirm their email address.

### Enable export for a group

Prerequisite:

- You must have the Owner role for the group.

To enable import and export for a group:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General**.
1. Expand **Visibility and access controls**.
1. In the **Import sources** section, select the checkboxes for the sources you want.

### Export a group

Prerequisites:

- You must have the Owner role for the group.

To export the contents of a group:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Settings > General**.
1. In the **Advanced** section, select **Export Group**.
1. After the export is generated, you should receive an email with a link to the [exported contents](#exported-contents)
   in a compressed tar archive, with contents in NDJSON format.
1. Alternatively, you can download the export from the UI:

   1. Return to your group's **Settings > General** page.
   1. In the **Advanced** section, select **Download export**.
      You can also generate a new file by selecting **Regenerate export**.

You can also export a group [using the API](../../../api/group_import_export.md).

### Import the group

1. Create a new group:
   - On the top bar, select **Create new…** (**{plus-square}**) and then **New group**.
   - On an existing group's page, select **New subgroup**.
1. Select **Import group**.
1. Enter your group name.
1. Accept or modify the associated group URL.
1. Select **Choose file**.
1. Select the file that you exported in the [Export a group](#export-a-group) section.
1. To begin importing, select **Import group**.

Your newly imported group page appears after the operation completes.

NOTE:
The maximum import file size can be set by the administrator, default is `0` (unlimited).
As an administrator, you can modify the maximum import file size. To do so, use the `max_import_size` option in the
[Application settings API](../../../api/settings.md#change-application-settings) or the
[Admin Area](../../admin_area/settings/account_and_limit_settings.md).
Default [modified](https://gitlab.com/gitlab-org/gitlab/-/issues/251106) from 50 MB to 0 in GitLab 13.8.

### Rate limits

To help avoid abuse, by default, users are rate limited to:

| Request Type     | Limit                                    |
| ---------------- | ---------------------------------------- |
| Export           | 6 groups per minute                |
| Download export  | 1 download per group per minute  |
| Import           | 6 groups per minute                |

## Automate group and project import **(PREMIUM)**

For information on automating user, group, and project import API calls, see
[Automate group and project import](../../project/import/index.md#automate-group-and-project-import).
