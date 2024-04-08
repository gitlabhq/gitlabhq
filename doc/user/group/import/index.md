---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Migrate GitLab groups and projects by using direct transfer

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/249160) in GitLab 13.7 for group resources [with a flag](../../feature_flags.md) named `bulk_import`. Disabled by default.
> - Group items [enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/338985) in GitLab 14.3.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267945) in GitLab 14.4 for project resources [with a flag](../../feature_flags.md) named `bulk_import_projects`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/339941) in GitLab 15.6.
> - New application setting `bulk_import_enabled` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/383268) in GitLab 15.8. `bulk_import` feature flag removed.
> - `bulk_import_projects` feature flag [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/339941) in GitLab 15.10.

You can migrate GitLab groups:

- From self-managed GitLab to GitLab.com.
- From GitLab.com to self-managed GitLab.
- From one self-managed GitLab instance to another.
- Between groups in the same GitLab instance.

You can migrate groups in two ways:

- By direct transfer (recommended).
- By [uploading an export file](../../project/settings/import_export.md).

If you migrate from GitLab.com to self-managed GitLab, an administrator can create users on the self-managed GitLab instance.

On self-managed GitLab, by default [migrating group items](#migrated-group-items) is not available. To show the
feature, an administrator can [enable it in application settings](../../../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer).

Migrating groups by direct transfer copies the groups from one place to another. You can:

- Copy many groups at once.
- In the GitLab UI, copy top-level groups to:
  - Another top-level group.
  - The subgroup of any existing top-level group.
  - Another GitLab instance, including GitLab.com.
- In the [API](../../../api/bulk_imports.md), copy top-level groups and subgroups to these locations.
- Copy groups with projects (in [Beta](../../../policy/experiment-beta-support.md#beta) and not ready for production
  use) or without projects. Copying projects with groups is available:
  - On GitLab.com by default.

Not all group and project resources are copied. See list of copied resources below:

- [Migrated group items](#migrated-group-items).
- [Migrated project items](#migrated-project-items).

WARNING:
Importing groups with projects is in [Beta](../../../policy/experiment-beta-support.md#beta). This feature is not
ready for production use.

We invite you to leave your feedback about migrating by direct transfer in
[the feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/284495).

If you want to move groups instead of copying groups, you can [transfer groups](../manage.md#transfer-a-group) if the
groups are in the same GitLab instance. Transferring groups is a faster and more complete option.

## Known issues

- Because of [issue 406685](https://gitlab.com/gitlab-org/gitlab/-/issues/406685), files with a filename longer than 255 characters are not migrated.
- In GitLab 16.1 and earlier, you should **not** use direct transfer with
  [scheduled scan execution policies](../../../user/application_security/policies/scan-execution-policies.md).
- For a list of other known issues, see [epic 6629](https://gitlab.com/groups/gitlab-org/-/epics/6629).
- In GitLab 16.9 and earlier, because of [issue 438422](https://gitlab.com/gitlab-org/gitlab/-/issues/438422), you might see the
  `DiffNote::NoteDiffFileCreationError` error. When this error occurs, the diff of a note on a merge request's diff
  is missing, but the note and the merge request are still imported.

## Estimating migration duration

Estimating the duration of migration by direct transfer is difficult. The following factors affect migration duration:

- Hardware and database resources available on the source and destination GitLab instances. More resources on the source and destination instances can result in
  shorter migration duration because:
  - The source instance receives API requests, and extracts and serializes the entities to export.
  - The destination instance runs the jobs and creates the entities in its database.
- Complexity and size of data to be exported. For example, imagine you want to migrate two different projects with 1000 merge requests each. The two projects can take
  very different amounts of time to migrate if one of the projects has a lot more attachments, comments, and other items on the merge requests. Therefore, the number
  of merge requests on a project is a poor predictor of how long a project will take to migrate.

There's no exact formula to reliably estimate a migration. However, the average durations of each pipeline worker importing a project relation can help you to get an idea of how long importing your projects might take:

| Project resource type       | Average time (in seconds) to import a record |
|:----------------------------|:---------------------------------------------|
| Empty Project               | 2.4                                          |
| Repository                  | 20                                           |
| Project Attributes          | 1.5                                          |
| Members                     | 0.2                                          |
| Labels                      | 0.1                                          |
| Milestones                  | 0.07                                         |
| Badges                      | 0.1                                          |
| Issues                      | 0.1                                          |
| Snippets                    | 0.05                                         |
| Snippet Repositories        | 0.5                                          |
| Boards                      | 0.1                                          |
| Merge Requests              | 1                                            |
| External Pull Requests      | 0.5                                          |
| Protected Branches          | 0.1                                          |
| Project Feature             | 0.3                                          |
| Container Expiration Policy | 0.3                                          |
| Service Desk Setting        | 0.3                                          |
| Releases                    | 0.1                                          |
| CI Pipelines                | 0.2                                          |
| Commit Notes                | 0.05                                         |
| Wiki                        | 10                                           |
| Uploads                     | 0.5                                          |
| LFS Objects                 | 0.5                                          |
| Design                      | 0.1                                          |
| Auto DevOps                 | 0.1                                          |
| Pipeline Schedules          | 0.5                                          |
| References                  | 5                                            |
| Push Rule                   | 0.1                                          |

If you are migrating large projects and encounter problems with timeouts or duration of the migration, see [Reducing migration duration](#reducing-migration-duration).

## Limits

> - Eight hour time limit on migrations [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/429867) in GitLab 16.7.

Hardcoded limits apply on migration by direct transfer.

| Limit       | Description                                                                                                                                                                     |
|:------------|:--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 6           | Maximum number of migrations permitted by a destination GitLab instance per minute per user. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/386452) in GitLab 15.9. |
| 210 seconds | Maximum number of seconds to wait for decompressing an archive file.                                                                                                            |
| 50 MB       | Maximum length an NDJSON row can have.                                                                                                                                          |
| 5 minutes   | Maximum number of seconds until an empty export status on source instance is raised.                                                                                            |

[Configurable limits](../../../administration/settings/account_and_limit_settings.md) are also available.

In GitLab 16.3 and later, the following previously hard-coded settings are [configurable](https://gitlab.com/gitlab-org/gitlab/-/issues/384976):

- Maximum relation size that can be downloaded from the source instance (set to 5 GiB).
- Maximum size of a decompressed archive (set to 10 GiB).

You can test the maximum relation size limit using these APIs:

- [Group relations export API](../../../api/group_relations_export.md).
- [Project relations export API](../../../api/project_relations_export.md)

If either API produces files larger than the maximum relation size limit, group migration by direct transfer fails.

## Visibility rules

After migration:

- Private groups and projects stay private.
- Internal groups and projects:
  - Stay internal when copied into an internal group unless internal visibility is [restricted](../../../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels). In that case, the groups and projects become private.
  - Become private when copied into a private group.
- Public groups and projects:
  - Stay public when copied into a public group unless public visibility is [restricted](../../../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels). In that case, the groups and projects become internal.
  - Become internal when copied into an internal group unless internal visibility is [restricted](../../../administration/settings/visibility_and_access_controls.md#restrict-visibility-levels). In that case, the groups and projects become private.
  - Become private when copied into a private group.

If you used a private network on your source instance to hide content from the general public,
make sure to have a similar setup on the destination instance, or to import into a private group.

## Memberships

> - Importing of shared and inherited shared members was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129017) in GitLab 16.3.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148220) in GitLab 16.11, shared and inherited shared members are no longer imported as direct members if they are already shared or inherited shared members of the imported group or project.

Group and project members are imported if the [user account prerequisites](#user-accounts) are followed.

All [direct and indirect](../../../user/project/members/index.md#membership-types) members are imported.

Indirect members are imported as [direct members](../../project/members/index.md#membership-types) if:

- They are not already an indirect member.
- They are an indirect member, but have a lower [permission](../../../user/permissions.md).

## Prerequisites

> - Requirement for Maintainer role instead of Developer role introduced in GitLab 16.0 and backported to GitLab 15.11.1 and GitLab 15.10.5.

Before migrating by using direct transfer, see the following prerequisites.

### Network

- The network connection between instances or GitLab.com must support HTTPS.
- Firewalls must not block the connection between the source and destination GitLab instances.

### Versions

The source GitLab instance must be running GitLab 14.0 or later to import groups and GitLab 14.4 or later to import
projects. However, to maximize the chance of a successful and performant migration, you should:

- To take advantage of [batched exports and imports](https://gitlab.com/groups/gitlab-org/-/epics/9036) of relations,
  update the source and destinations instances to GitLab 16.2 or later.
- Migrate between versions that are as new as possible. Update the source and destination instances to as late a version
  as possible to take advantage of bug fixes and improvements added over time.

We have successfully tested migrations between a source instance running GitLab 16.2 and a destination instance running
GitLab 16.8.

### Configuration

- Both GitLab instances must have group migration by direct transfer
  [enabled in application settings](../../../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer)
  by an instance administrator.
- You must have a
  [personal access token](../../../user/profile/personal_access_tokens.md) for
  the source GitLab instance:
  - For GitLab 15.1 and later source instances, the personal access token must
    have the `api` scope.
  - For GitLab 15.0 and earlier source instances, the personal access token must
    have both the `api` and `read_repository` scopes.
- You must have the Owner role on the source group to migrate from.
- You must have a role in the destination namespace that enables you to
  [create a subgroup](../../group/subgroups/index.md#create-a-subgroup) in that
  namespace.
- To import items stored in object storage, you must either:
  - [Configure `proxy_download`](../../../administration/object_storage.md#configure-the-common-parameters).
  - Ensure that the destination GitLab instance has access to the object storage of the source GitLab instance.
- You cannot import groups with projects when the source instance or group has **Default project creation protection** set
  to **No one**. If required, this setting can be changed:
  - For [a whole instance](../../../administration/settings/visibility_and_access_controls.md#define-which-roles-can-create-projects).
  - For [specific groups](../index.md#specify-who-can-add-projects-to-a-group).

### User accounts

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

## Connect the source GitLab instance

Create the group you want to import to and connect the source GitLab instance:

1. Create either:
   - A new group. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New group**. Then select **Import group**.
   - A new subgroup. On existing group's page, either:
     - Select **New subgroup**.
     - On the left sidebar, at the top, select **Create new** (**{plus}**) and **New subgroup**. Then select the **import an existing group** link.
1. Enter the base URL of a GitLab instance running GitLab 14.0 or later.
1. Enter the [personal access token](../../../user/profile/personal_access_tokens.md) for your source GitLab instance.
1. Select **Connect instance**.

## Select the groups and projects to import

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/385689) in GitLab 15.8, option to import groups with or without projects.

After you have authorized access to the source GitLab instance, you are redirected to the GitLab group
importer page. Here you can see a list of the top-level groups on the connected source instance where you have the Owner
role.

1. By default, the proposed group namespaces match the names as they exist in source instance, but based on your permissions, you can choose to edit these names before you proceed to import any of them.
1. Next to the groups you want to import, select either:
   - **Import with projects**. If this is not available, see [prerequisites](#prerequisites).
   - **Import without projects**.
1. The **Status** column shows the import status of each group. If you leave the page open, it updates in real-time.
1. After a group has been imported, select its GitLab path to open its GitLab URL.

WARNING:
Importing groups with projects is in [Beta](../../../policy/experiment-beta-support.md#beta). This feature is not
ready for production use.

## Group import history

> - **Partially completed** status [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/394727) in GitLab 16.7.

You can view all groups migrated by you by direct transfer listed on the group import history page. This list includes:

- Paths of source groups.
- Paths of destination groups.
- Start date of each import.
- Status of each import.
- Error details if any errors occurred.

To view group import history:

1. Sign in to GitLab.
1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New group**.
1. Select **Import group**.
1. In the upper-right corner, select **History**.
1. If there are any errors for a particular import, select **See failures** to see their details.

## Review results of the import

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429109) in GitLab 16.6 [with a flag](../../feature_flags.md) named `bulk_import_details_page`. Enabled by default.
> - Feature flag `bulk_import_details_page` removed in GitLab 16.8.
> - Details for partially completed and completed imports [added](https://gitlab.com/gitlab-org/gitlab/-/issues/437874) in GitLab 16.9.

To review the results of an import:

1. Go to the [Group import history page](#group-import-history).
1. To see the details of a failed import, select the **See failures** link on any import with a **Failed** or **Partially completed** status.
1. If the import has a **Partially completed** or **Complete** status, to see which items were and were not imported, select **Details**.

## Cancel a running import

To cancel a running import:

1. Start a [Rails console session](../../../administration/operations/rails_console.md#starting-a-rails-console-session)
   on the destination GitLab instance.
1. Find the last import by running the following command. Replace `USER_ID` with the user ID of the user that started the import:

   ```ruby
   bulk_import = BulkImport.where(user_id: USER_ID).last
   ```

1. Cause the import and all items associated with it to fail by running the following command:

   ```ruby
   bulk_import.entities.each do |entity|
     entity.trackers.each do |tracker|
       tracker.batches.each(&:fail_op!)
     end
     entity.trackers.each(&:fail_op!)
     entity.fail_op!
   end
   bulk_import.fail_op!
   ```

Cancelling a `bulk_import` doesn't stop workers that are exporting the project on the source instance, but prevents the
destination instance from:

- Asking the source instance for more projects to be exported.
- Making other API calls to the source instance for various checks and information.

## Migrated group items

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
| Group labels <sup>2</sup> | [GitLab 13.9](https://gitlab.com/gitlab-org/gitlab/-/issues/292429)    |
| Iterations           | [GitLab 13.10](https://gitlab.com/gitlab-org/gitlab/-/issues/292428)        |
| Iteration cadences   | [GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96570)  |
| Members <sup>3</sup> | [GitLab 13.9](https://gitlab.com/gitlab-org/gitlab/-/issues/299415) |
| Group milestones     | [GitLab 13.10](https://gitlab.com/gitlab-org/gitlab/-/issues/292427)        |
| Namespace settings   | [GitLab 14.10](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85128) |
| Release milestones   | [GitLab 15.0](https://gitlab.com/gitlab-org/gitlab/-/issues/339422)         |
| Subgroups            | [GitLab 13.7](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18938)  |
| Uploads              | [GitLab 13.7](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18938)  |

1. Epic resource state events [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/291983) in GitLab 15.4, label
   associations [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/62074) in GitLab 13.12, state and
   state ID [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/28203) in GitLab 13.7, and system note
   metadata [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/63551) in GitLab 14.0.
1. Group Labels cannot retain any associated Label Priorities during import. These labels will need to be re-prioritized manually
   once the relevant Project is migrated to the destination instance.
1. See [Memberships](#memberships).

### Excluded items

Some group items are excluded from migration because they either:

- May contain sensitive information: CI/CD variables, webhooks, and deploy tokens.
- Are not supported: push rules.

## Migrated project items

DETAILS:
**Status:** Beta

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
Migrating projects when migrating groups by direct transfer is in [Beta](../../../policy/experiment-beta-support.md#beta)
and is not ready for production use.

Project items that are migrated to the destination GitLab instance include:

| Project item                            | Introduced in                                                              |
|:----------------------------------------|:---------------------------------------------------------------------------|
| Projects                                | [GitLab 14.4](https://gitlab.com/gitlab-org/gitlab/-/issues/267945)        |
| Auto DevOps                             | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/issues/339410)        |
| Badges                                  | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75029) |
| Branches (including protected branches) <sup>1</sup> | [GitLab 14.7](https://gitlab.com/gitlab-org/gitlab/-/issues/339414) |
| CI Pipelines                            | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/issues/339407)        |
| Commit comments                         | [GitLab 15.10](https://gitlab.com/gitlab-org/gitlab/-/issues/391601)       |
| Designs                                 | [GitLab 15.1](https://gitlab.com/gitlab-org/gitlab/-/issues/339421)        |
| Issues                                  | [GitLab 14.4](https://gitlab.com/gitlab-org/gitlab/-/issues/267946)        |
| Issue boards                            | [GitLab 14.4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/71661) |
| Labels                                  | [GitLab 14.4](https://gitlab.com/gitlab-org/gitlab/-/issues/339419)        |
| LFS Objects                             | [GitLab 14.8](https://gitlab.com/gitlab-org/gitlab/-/issues/339405)        |
| Members <sup>2</sup>                    | [GitLab 14.8](https://gitlab.com/gitlab-org/gitlab/-/issues/341886)        |
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

**Footnotes:**

1. Imported branches respect the [default branch protection settings](../../project/protected_branches.md)
   of the destination group, which could cause an unprotected branch to be imported as protected.
1. See [Memberships](#memberships).

### Issue-related items

Issue-related project items that are migrated to the destination GitLab instance include:

| Issue-related project item      | Introduced in                                                              |
|:--------------------------------|:---------------------------------------------------------------------------|
| Issue iterations                | [GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/96184) |
| Issue resource state events     | [GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/291983)        |
| Issue resource milestone events | [GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/291983)        |
| Issue resource iteration events | [GitLab 15.4](https://gitlab.com/gitlab-org/gitlab/-/issues/291983)        |
| Merge request URL references    | [GitLab 15.6](https://gitlab.com/gitlab-org/gitlab/-/issues/267947)        |
| Time tracking                   | [GitLab 14.4](https://gitlab.com/gitlab-org/gitlab/-/issues/267946)        |

### Merge request-related items

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

### Setting-related items

Setting-related project items that are migrated to the destination GitLab instance include:

| Setting-related project item | Introduced in                                                              |
|:-----------------------------|:---------------------------------------------------------------------------|
| Avatar                       | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75249) |
| Container expiration policy  | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75653) |
| Project properties           | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75898) |
| Service Desk                 | [GitLab 14.6](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/75653) |

### Excluded items

Some project items are excluded from migration because they either:

- May contain sensitive information:
  - CI/CD variables
  - Deploy keys
  - Deploy tokens
  - Pipeline schedule variables
  - Pipeline triggers
  - Webhooks
- Are not supported:
  - Agents
  - Container Registry
  - Environments
  - Feature flags
  - Infrastructure Registry
  - Package registry
  - Pages domains
  - Remote mirrors

## Troubleshooting

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

### Stale imports

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352985) in GitLab 14.10.

When troubleshooting group migration, an import may not complete because the import workers took
longer than 8 hours to execute. In this case, the `status` of either a `BulkImport` or
`BulkImport::Entity` is `3` (`timeout`):

```ruby
# Get relevant import records
import = BulkImports::Entity.where(namespace_id: Group.id).map(&:bulk_import)

import.status #=> 3 means that the import timed out.
```

### Error: `404 Group Not Found`

If you attempt to import a group that has a path comprised of only numbers (for example, `5000`), GitLab attempts to
find the group by ID instead of the path. This causes a `404 Group Not Found` error in GitLab 15.4 and earlier.

To solve this, you must change the source group path to include a non-numerical character using either:

- The GitLab UI:

  1. On the left sidebar, select **Search or go to** and find your group.
  1. Select **Settings > General**.
  1. Expand **Advanced**.
  1. Under **Change group URL**, change the group URL to include non-numeric characters.

- The [Groups API](../../../api/groups.md#update-group).

### Other `404` errors

You can receive other `404` errors when importing a group, for example:

```json
"exception_message": "Unsuccessful response 404 from [FILTERED] Bo...",
"exception_class": "BulkImports::NetworkError",
```

This error indicates a problem transferring from the _source_ instance. To solve this, check that you have met the [prerequisites](#prerequisites) on the source
instance.

### Reducing migration duration

A single direct transfer migration runs 5 entities (groups or projects) per import at a time, independent of the number of workers available on the destination instance.
That said, having more workers on the destination instance speeds up migration by decreasing the time it takes to import each entity.

Increasing the number of workers on the destination instance helps reduce the migration duration until the source instance hardware resources are saturated. Exporting and importing relations in batches (proposed in [epic 9036](https://gitlab.com/groups/gitlab-org/-/epics/9036)) will make having enough available workers on
the destination instance even more useful.

The number of workers on the source instance should be enough to export the 5 concurrent entities in parallel (for each running import). Otherwise, there can be
delays and potential timeouts as the destination is waiting for exported data to become available.

Distributing projects in different groups helps to avoid timeouts. If several large projects are in the same group, you can:

1. Move large projects to different groups or subgroups.
1. Start separate migrations each group and subgroup.

The GitLab UI can only migrate top-level groups. Using the API, you can also migrate subgroups.
