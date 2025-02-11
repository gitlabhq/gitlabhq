---
stage: Foundations
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrate groups and projects by using direct transfer
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

To migrate GitLab groups and projects by using direct transfer, you:

1. Fulfill the prerequisites.
1. Connect the source GitLab instance.
1. Select groups and projects to migrate and begin the migration.
1. Review the results of the import.

If there are any problems, you can:

1. Cancel or retry the migration.
1. Check the [troubleshooting information](troubleshooting.md).

## Prerequisites

> - Requirement for Maintainer role instead of Developer role introduced in GitLab 16.0 and backported to GitLab 15.11.1 and GitLab 15.10.5.

Before migrating by using direct transfer, see the following prerequisites.

### Network

- The network connection between instances or GitLab.com must support HTTPS.
- Firewalls must not block the connection between the source and destination GitLab instances.

### Versions

To maximize the chance of a successful and performant migration, you should:

- Upgrade both the source and destination instances to GitLab 16.8 or later to use bulk import and export of relations.
  For more information, see [epic 9036](https://gitlab.com/groups/gitlab-org/-/epics/9036).
- Migrate between versions that are as new as possible. Update the source and destination instances to as late a version
  as possible to take advantage of bug fixes and improvements added over time.
- [Configure Sidekiq](../../project/import/_index.md#sidekiq-configuration) properly.

We have successfully tested migrations between a source instance running GitLab 16.2 and a destination instance running
GitLab 16.8.

### Configuration

- Both GitLab instances must have group migration by direct transfer
  [enabled in application settings](../../../administration/settings/import_and_export_settings.md#enable-migration-of-groups-and-projects-by-direct-transfer)
  by an instance administrator.
- You must have a
  [personal access token](../../profile/personal_access_tokens.md) for
  the source GitLab instance:
  - For GitLab 15.1 and later source instances, the personal access token must
    have the `api` scope.
  - For GitLab 15.0 and earlier source instances, the personal access token must
    have both the `api` and `read_repository` scopes.
- You must have the Owner role on the source group to migrate from.
- You must have a role in the destination namespace that enables you to
  [create a subgroup](../subgroups/_index.md#create-a-subgroup) in that
  namespace.
- To import project snippets, ensure snippets are
  [enabled in the source project](../../snippets.md#change-default-visibility-of-snippets).
- To import items stored in object storage, you must either:
  - [Configure `proxy_download`](../../../administration/object_storage.md#configure-the-common-parameters).
  - Ensure that the destination GitLab instance has access to the object storage of the source GitLab instance.
- You cannot import groups with projects when the source instance or group has **Default project creation protection** set
  to **No one**. If required, this setting can be changed:
  - For [a whole instance](../../../administration/settings/visibility_and_access_controls.md#define-which-roles-can-create-projects).
  - For [specific groups](../_index.md#specify-who-can-add-projects-to-a-group).

## User contribution and membership mapping

DETAILS:
**Offering:** GitLab Self-Managed, GitLab Dedicated

> - Mapping of shared and inherited shared members as direct members was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/129017) in GitLab 16.3.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148220) in GitLab 16.11, shared and inherited shared members are no longer mapped as direct members if they are already shared or inherited shared members of the imported group or project.
> - Full support for mapping inherited membership [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/458834) in GitLab 17.1.
> - Removed from direct transfer on GitLab.com in GitLab 17.5 in favor of [the alternative](../../project/import/_index.md#user-contribution-and-membership-mapping).
> - Removed as the default direct transfer method on GitLab Self-Managed and GitLab Dedicated in GitLab 17.7 in favor of [the alternative](../../project/import/_index.md#user-contribution-and-membership-mapping).

This method of user contribution and membership mapping is available for
GitLab Self-Managed when `importer_user_mapping` and `bulk_import_importer_user_mapping` are disabled.
These feature flags are enabled by default.
For information on the default method available for GitLab Self-Managed and GitLab.com,
see [user contribution and membership mapping](../../project/import/_index.md#user-contribution-and-membership-mapping).

Users are never created during a migration. Instead, contributions and membership of users on the source instance are
mapped to users on the destination instance. The type of mapping of a user's membership depends on the
[membership type](../../project/members/_index.md#membership-types) on source instance:

- Direct memberships are mapped as direct memberships on the destination instance.
- Inherited memberships are mapped as inherited memberships on the destination instance.
- Shared memberships are mapped as direct memberships on the destination instance unless the user has an existing shared
  membership. Full support for mapping shared memberships is proposed in
  [issue 458345](https://gitlab.com/gitlab-org/gitlab/-/issues/458345).

When mapping [inherited and shared](../../project/members/_index.md#membership-types) memberships, if the user
has an existing membership in the destination namespace with a [higher role](../../permissions.md#roles) than
the one being mapped, the membership is mapped as a direct membership instead. This ensures the member does not get
elevated permissions.

NOTE:
There is a [known issue](_index.md#known-issues) affecting the mapping of shared memberships.

### Configure users on destination instance

To ensure GitLab maps users and their contributions correctly between the source and destination instances:

1. Create the required users on the destination GitLab instance. You can create users with the API only on self-managed instances because it requires
   administrator access. When migrating to GitLab.com or GitLab Self-Managed you can:
   - Create users manually.
   - Set up or use your existing [SAML SSO provider](../saml_sso/_index.md) and leverage user synchronization of SAML SSO groups supported through
     [SCIM](../saml_sso/scim_setup.md). You can
     [bypass the GitLab user account verification with verified email domains](../saml_sso/_index.md#bypass-user-email-confirmation-with-verified-domains).
1. Ensure that users have a [public email](../../profile/_index.md#set-your-public-email) on the source GitLab instance that matches any confirmed email address on the destination GitLab instance. Most
   users receive an email asking them to confirm their email address.
1. If users already exist on the destination instance and you use [SAML SSO for GitLab.com groups](../saml_sso/_index.md), all users must
   [link their SAML identity to their GitLab.com account](../saml_sso/_index.md#link-saml-to-your-existing-gitlabcom-account).

There is no way in the GitLab UI or API to automatically set public email addresses for users. If you need to set
a lot of user accounts to have public email addresses, see
[issue 284495](https://gitlab.com/gitlab-org/gitlab/-/issues/284495#note_1910159855) for a potential workaround.

## Connect the source GitLab instance

On the destination GitLab instance, create the group you want to import to and connect the source GitLab instance:

1. Create either:
   - A new group. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New group**. Then select **Import group**.
   - A new subgroup. On existing group's page, either:
     - Select **New subgroup**.
     - On the left sidebar, at the top, select **Create new** (**{plus}**) and **New subgroup**. Then select the **import an existing group** link.
1. Enter the base URL of a GitLab instance.
1. Enter the [personal access token](../../profile/personal_access_tokens.md) for your source GitLab instance.
1. Select **Connect instance**.

## Select the groups and projects to import

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/385689) in GitLab 15.8, option to import groups with or without projects.
> - **Import user memberships** checkbox [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/477734) in GitLab 17.6.

After you have authorized access to the source GitLab instance, you are redirected to the GitLab group importer page. Here you can see a list of the top-level groups on the connected source instance where you have the Owner role.

If you do not want to import all user memberships from the source instance, ensure the **Import user memberships** checkbox is cleared. For example, the source instance might have 200 members, but you might want to import 50 members only. After the import completes, you can add more members to groups and projects.

1. By default, the proposed group namespaces match the names as they exist in source instance, but based on your permissions, you can choose to edit these names before you proceed to import any of them. Group and project paths must conform to [naming rules](../../reserved_names.md#rules-for-usernames-project-and-group-names-and-slugs) and are normalized if necessary to avoid import failures.
1. Next to the groups you want to import, select either:
   - **Import with projects**. If this is not available, see [prerequisites](#prerequisites).
   - **Import without projects**.
1. The **Status** column shows the import status of each group. If you leave the page open, it updates in real-time.
1. After a group has been imported, select its GitLab path to open its GitLab URL.

WARNING:
Importing groups with projects is in [beta](../../../policy/development_stages_support.md#beta). This feature is not ready for production use.

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
1. If there are any errors for a particular import, select **Show errors** to see their details.

## Review results of the import

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429109) in GitLab 16.6 [with a flag](../../feature_flags.md) named `bulk_import_details_page`. Enabled by default.
> - Feature flag `bulk_import_details_page` removed in GitLab 16.8.
> - Details for partially completed and completed imports [added](https://gitlab.com/gitlab-org/gitlab/-/issues/437874) in GitLab 16.9.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/443492) in GitLab 17.0, an **Imported** badge to indicate that designs, epics, issues, merge requests, notes (system notes and comments), snippets, and user profile activity were imported.

To review the results of an import:

1. Go to the [Group import history page](#group-import-history).
1. To see the details of a failed import, select the **Show errors** link on any import with a **Failed** or **Partially completed** status.
1. If the import has a **Partially completed** or **Complete** status, to see which items were and were not imported, select **View details**.

You can also see that an item was imported when you see an **Imported** badge on some items in the GitLab UI.

## Cancel a running migration

If required, you can cancel a running migration by using either the REST API or a Rails console.

### Cancel with the REST API

For information on cancelling a running migration with the REST API, see
[Cancel a migration](../../../api/bulk_imports.md#cancel-a-migration).

### Cancel with a Rails console

To cancel a running migration with a Rails console:

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

## Retry failed or partially successful migrations

If your migrations fail, or partially succeed but are missing items, you can retry the migration. To retry a migration
of a:

- Top-level group and all of its subgroups and projects, use either the GitLab UI or the
  [GitLab REST API](../../../api/bulk_imports.md).
- Specific subgroups or projects, use the [GitLab REST API](../../../api/bulk_imports.md).
