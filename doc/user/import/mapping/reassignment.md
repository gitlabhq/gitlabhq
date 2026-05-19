---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Reassign contributions and memberships
---

Users with the Owner role for a top-level group can reassign contributions and memberships
from placeholder users to existing active non-bot users.
On the destination instance, users with the Owner role for a top-level group can:

- Request users to review reassignment of contributions and memberships [in the UI](#request-reassignment-in-ui)
  or [through a CSV file](#request-reassignment-by-using-a-csv-file).
  For a large number of placeholder users, you should use a CSV file.
  In both cases, users receive a request by email to accept or reject the reassignment.
  The reassignment starts only after the selected user
  [accepts the reassignment request](#accept-contribution-reassignment).
- Choose not to reassign contributions and memberships and [keep them assigned to placeholder users](#keep-as-placeholder).

On GitLab Self-Managed and GitLab Dedicated, administrators can reassign
contributions and memberships to active and inactive non-bot users immediately without their confirmation.
For more information, see [skip confirmation when administrators reassign placeholder users](../../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users).
To reassign contributions and memberships to administrators, see
[allow contribution mapping to administrators](../../../administration/settings/import_and_export_settings.md#allow-contribution-mapping-to-administrators).

## Bypass confirmation when reassigning placeholder users

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- [Introduced on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/544024) in GitLab 18.1 with a feature flag named `group_owner_placeholder_confirmation_bypass`. Disabled by default.
- [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/548946) in GitLab 18.4.
- [Generally available on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/569771) in GitLab 18.7. Feature flag `group_owner_placeholder_confirmation_bypass` removed.

{{< /history >}}

Prerequisites:

- You must have the Owner role for the group.

To bypass confirmation for [enterprise users](../../enterprise_user/_index.md)
when you reassign placeholders:

1. In the top bar, select **Search or go to** and find your group.
   This group must be at the top level.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **Permissions and group features**.
1. Under **Placeholder user confirmation**, select the
   **Reassign placeholders to enterprise users without user confirmation** checkbox.
1. In **When to restore user confirmation**,
   select an end date for bypassing user confirmation.
   The default value is one day.
1. Select **Save changes**.

### Reassigning contributions from multiple placeholder users

You can reassign all contributions initially assigned to a single placeholder user to a
single active regular user, service accounts, project bots, and group bots on the destination instance.
You cannot split contributions assigned to a single placeholder user among multiple users.

You can reassign contributions from multiple placeholder users to the same user
on the destination instance if the placeholder users are from:

- Different source instances
- The same source instance and are imported to different top-level groups on the destination instance

If an assigned user becomes inactive before accepting the reassignment request,
the pending reassignment remains linked to the user until they accept it.

Users that receive a reassignment request can:

- [Accept the request](#accept-contribution-reassignment). All contributions and membership previously attributed to the placeholder user are re-attributed
  to the accepting user. This process can take a few minutes, depending on the number of contributions.
- [Reject the request](#reject-contribution-reassignment) or report it as spam. This option is available in the reassignment
  request email.

When you reassign contributions to service accounts, project bots, and group bots,
the reassignment request is automatically approved.

In subsequent imports to the same top-level group, contributions and memberships that belong to the same source user
are mapped automatically to the user who previously accepted reassignments for that source user.

On GitLab Self-Managed and GitLab Dedicated, administrators can reassign
contributions and memberships to active and inactive non-bot users immediately without their confirmation.
For more information, see [skip confirmation when administrators reassign placeholder users](../../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users).
To reassign contributions and memberships to administrators, see
[allow contribution mapping to administrators](../../../administration/settings/import_and_export_settings.md#allow-contribution-mapping-to-administrators).

### Completing the reassignment

The reassignment process must be fully completed before you:

- [Move an imported group in the same GitLab instance](../../group/manage.md#transfer-a-group).
- [Move an imported project to a different group](../../project/working_with_projects.md#transfer-a-project).
- Duplicate an imported issue.
- Promote an imported issue to an epic.

If the process isn't complete, contributions still assigned to placeholder users cannot be reassigned to real users and
they stay associated with placeholder users.

### Security considerations

Contribution and membership reassignment cannot be undone, so check everything carefully before you start.

Reassigning contributions and membership to an incorrect user poses a security threat, because the user becomes a member
of your group. They can, therefore, view information they should not be able to see.

Reassigning contributions to users with administrator access is disabled by default, but you can
[enable](../../../administration/settings/import_and_export_settings.md#allow-contribution-mapping-to-administrators) it.

#### Membership security considerations

Because of the GitLab permissions model, when a group or project is imported into an existing parent group, members of
the parent group are granted [inherited membership](../../project/members/_index.md#membership-types) of the imported group or project.

Selecting a user for contribution and membership reassignment who already has an
existing inherited membership of the imported group or project can affect how memberships
are reassigned to them.

GitLab does not allow a membership in a child project or group to have a lower role
than an inherited membership. If an imported membership for an assigned user has a lower role
than their existing inherited membership, the imported membership is not reassigned to the user.

This results in their membership for the imported group or project being higher than it was on the source.

### Request reassignment in UI

Prerequisites:

- You must have the Owner role for the group.

You can reassign contributions and memberships in the top-level group.
To request reassignment of contributions and memberships:

1. In the top bar, select **Search or go to** and find your group.
   This group must be at the top level.
1. In the left sidebar, select **Manage** > **Members**.
1. Select the **Placeholders** tab.
1. Go to **Awaiting reassignment** sub-tab, where placeholders are listed in a table.
1. For each placeholder, review information in table columns **Placeholder user** and **Source**.
1. In the **Reassign placeholder to** column, select a user from the dropdown list.
1. Select **Reassign**.

Contributions of only one placeholder user can be reassigned to an active non-bot user on destination instance.

Before a user accepts the reassignment, you can [cancel the request](#cancel-reassignment-request).

On GitLab Self-Managed and GitLab Dedicated, administrators can reassign
contributions and memberships to active and inactive non-bot users immediately without their confirmation.
For more information, see [skip confirmation when administrators reassign placeholder users](../../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users).
To reassign contributions and memberships to administrators, see
[allow contribution mapping to administrators](../../../administration/settings/import_and_export_settings.md#allow-contribution-mapping-to-administrators).

### Request reassignment by using a CSV file

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/455901) in GitLab 17.10 [with a flag](../../../administration/feature_flags/_index.md) named `importer_user_mapping_reassignment_csv`. Enabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/478022) in GitLab 18.0. Feature flag `importer_user_mapping_reassignment_csv` removed.

{{< /history >}}

Prerequisites:

- You must have the Owner role for the group.

For a large number of placeholder users, you might want to
reassign contributions and memberships by using a CSV file.
You can download a prefilled CSV template with the following information.
For example:

| Source host          | Import type | Source user identifier | Source user name | Source username |
|----------------------|-------------|------------------------|------------------|-----------------|
| `gitlab.example.com` | `gitlab`    | `alice`                | `Alice Coder`    | `a.coder`       |

Do not update **Source host**, **Import type**, or **Source user identifier**.
This information locates the corresponding database record
after you've uploaded the completed CSV file.
**Source user name** and **Source username** identify the source user
and are not used after you've uploaded the CSV file.

You do not have to update every row of the CSV file.
Only rows with **GitLab username** or **GitLab public email** are processed.
All other rows are skipped.

To request reassignment of contributions and memberships by using a CSV file:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Manage** > **Members**.
1. Select the **Placeholders** tab.
1. Select **Reassign with CSV**.
1. Download the prefilled CSV template.
1. In **GitLab username** or **GitLab public email**, enter the username or public email address
   of the GitLab user on the destination instance.
   Instance administrators can reassign users with any confirmed email address.
1. Upload the completed CSV file.
1. Select **Reassign**.

You can assign only contributions from a single placeholder user
to each active non-bot user on the destination instance.
Users receive an email to review and [accept any contributions](#accept-contribution-reassignment) you've reassigned to them.
You can [cancel the reassignment request](#cancel-reassignment-request) before the user reviews it.

On GitLab Self-Managed and GitLab Dedicated, administrators can reassign
contributions and memberships to active and inactive non-bot users immediately without their confirmation.
For more information, see [skip confirmation when administrators reassign placeholder users](../../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users).
To reassign contributions and memberships to administrators, see
[allow contribution mapping to administrators](../../../administration/settings/import_and_export_settings.md#allow-contribution-mapping-to-administrators).

After you reassign contributions, GitLab sends you an email with the number of:

- Successfully processed rows
- Unsuccessfully processed rows
- Skipped rows

If any rows have not been successfully processed, the email has a CSV file with more detailed results.

To reassign placeholder users in bulk without using the UI,
see [Group placeholder reassignments API](../../../api/group_placeholder_reassignments.md).

### Keep as placeholder

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/535431) in GitLab 18.5, the operation can be undone.

{{< /history >}}

You might not want to reassign contributions and memberships to users on the destination instance. For example, you
might have former employees that contributed on the source instance, but they do not exist as users on the destination
instance.

In these cases, you can keep the contributions assigned to placeholder users. Placeholder users do not keep
membership information because they [cannot be members of projects or groups](post_migration_mapping.md#placeholder-user-attributes).

Because names and usernames of placeholder users resemble names and usernames of source users, you keep a lot of
historical context.

You can keep contributions assigned to placeholder users either one at a time or in bulk.
When you reassign contributions in bulk, the entire namespace and users with the following
[reassignment statuses](#view-and-filter-by-reassignment-status) are affected:

- `Not started`
- `Rejected`

To keep placeholder users one at a time:

1. In the top bar, select **Search or go to** and find your group.
   This group must be at the top level.
1. In the left sidebar, select **Manage** > **Members**.
1. Select the **Placeholders** tab.
1. Go to **Awaiting reassignment** sub-tab, where placeholders are listed in a table.
1. Find placeholder user you want to keep by reviewing **Placeholder user** and **Source** columns.
1. In **Reassign placeholder to** column, select **Do not reassign**.
1. Select **Confirm**.

To keep placeholder users in bulk:

1. In the top bar, select **Search or go to** and find your group.
   This group must be at the top level.
1. In the left sidebar, select **Manage** > **Members**.
1. Select the **Placeholders** tab.
1. Above the list, select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Keep all as placeholders**.
1. On the confirmation dialog, select **Confirm**.

To undo the operation:

1. In the top bar, select **Search or go to** and find your group.
   This group must be at the top level.
1. In the left sidebar, select **Manage** > **Members**.
1. Select the **Placeholders** tab.
1. Go to **Reassigned** sub-tab, where placeholders are listed in a table.
1. Select **Undo** in the correct row.

### Cancel reassignment request

Before a user accepts a reassignment request, you can cancel the request:

1. In the top bar, select **Search or go to** and find your group.
   This group must be at the top level.
1. In the left sidebar, select **Manage** > **Members**.
1. Select the **Placeholders** tab.
1. Go to **Awaiting reassignment** sub-tab, where placeholders are listed in a table.
1. Select **Cancel** in the correct row.

### Notify user again about pending reassignment requests

If a user is not acting on a reassignment request, you can prompt them again by sending another email:

1. In the top bar, select **Search or go to** and find your group.
   This group must be at the top level.
1. In the left sidebar, select **Manage** > **Members**.
1. Select the **Placeholders** tab.
1. Go to **Awaiting reassignment** sub-tab, where placeholders are listed in a table.
1. Select **Notify** in the correct row.

### View and filter by reassignment status

To view the reassignment status of all placeholder users:

1. In the top bar, select **Search or go to** and find your group.
   This group must be at the top level.
1. In the left sidebar, select **Manage** > **Members**.
1. Select the **Placeholders** tab.
1. Go to **Awaiting reassignment** sub-tab, where placeholders are listed in a table.
1. See the status of each placeholder user in **Reassignment status** column.

In the **Awaiting reassignment** tab, possible statuses are:

- `Not started` - Reassignment has not started.
- `Pending approval` - Reassignment is waiting on user approval.
- `Reassigning` - Reassignment is in progress.
- `Rejected` - Reassignment was rejected by user.
- `Failed` - Reassignment failed.

In the **Reassigned** tab, possible statuses are:

- `Success` - Reassignment succeeded.
- `Kept as placeholder` - Placeholder user was made permanent.

By default, the table is sorted alphabetically by placeholder user name.
You can also sort the table by reassignment status.

## Confirm contribution reassignment

When [**Skip confirmation when administrators reassign placeholder users**](../../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users) is enabled:

- Administrators can reassign contributions immediately without user confirmation.
- Administrators can reassign contributions to active and inactive non-bot users.
- You receive an email informing you that you've been reassigned contributions.

If this setting is not enabled, you can [accept](#accept-contribution-reassignment)
or [reject](#reject-contribution-reassignment) the reassignment.

### Accept contribution reassignment

You might receive an email informing you that an import process took place and asking you to confirm reassignment of
contributions to yourself.

If you were informed about this import process, you must still review reassignment details very carefully. Details
listed in the email are:

- **Imported from** - The platform the imported content originates from. For example, another instance of GitLab,
  GitHub, or Bitbucket.
- **Original user** - The name and username of the user on the source platform. This could be your name and user name on
  that platform.
- **Imported to** - The name of the new platform, which can only be a GitLab instance.
- **Reassigned to** - Your full name and username on the GitLab instance.
- **Reassigned by** - The full name and username of your colleague or manager that performed the import.

### Reject contribution reassignment

If you receive an email asking you to confirm reassignment of contributions to yourself and you don't recognize or you
notice mistakes in this information:

1. Do not proceed at all or reject the contribution reassignment.
1. Talk to a trusted colleague or your manager.

### Security considerations

You must review the reassignment details of any reassignment request very carefully. If you were not already informed
about this process by a trusted colleague or your manager, take extra care.

Rather than accept any reassignments that you have any doubts about:

1. Don't act on the emails.
1. Talk to a trusted colleague or your manager.

Accept reassignments only from the users that you know and trust. Reassignment of contributions is permanent and cannot
be undone. Accepting the reassignment might cause contributions to be incorrectly attributed to you.

The contribution reassignment process starts only after you accept the reassignment request by selecting
**Approve reassignment** in GitLab. The process doesn't start by selecting links in the email.
