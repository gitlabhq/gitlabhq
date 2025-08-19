---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Import and migrate groups and projects
description: Repository migration, third-party repositories, and user contribution mapping.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Bring your existing work into GitLab and preserve your contribution history.
Consolidate projects from multiple platforms or transfer data between GitLab instances.

GitLab offers different methods to:

- Migrate GitLab groups and projects by using direct transfer.
- Import projects from a variety of supported sources.

## Migrate from GitLab to GitLab by using direct transfer

The best way to copy GitLab groups and projects between GitLab instances, or in the same GitLab instance, is
[by using direct transfer](../../group/import/_index.md).

Another option is to move GitLab groups using [group transfer](../../group/manage.md#transfer-a-group).

You can also copy GitLab projects by using a GitLab file export, which is a supported import source.

## Supported import sources

{{< history >}}

- All importers default to disabled for GitLab Self-Managed instances. This change was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/118970) in GitLab 16.0.

{{< /history >}}

The import sources that are available to you by default depend on which GitLab you use:

- GitLab.com: all available import sources are [enabled by default](../../gitlab_com/_index.md#default-import-sources).
- GitLab Self-Managed: no import sources are enabled by default and must be
  [enabled](../../../administration/settings/import_and_export_settings.md#configure-allowed-import-sources).

GitLab can import projects from these supported import sources.

| Import source                                 | Description |
|:----------------------------------------------|:------------|
| [Bitbucket Cloud](bitbucket.md)               | Using [Bitbucket.org as an OmniAuth provider](../../../integration/bitbucket.md), import Bitbucket repositories. |
| [Bitbucket Server](bitbucket_server.md)       | Import repositories from Bitbucket Server (also known as Stash). |
| [FogBugz](fogbugz.md)                         | Import FogBugz projects. |
| [Gitea](gitea.md)                             | Import Gitea projects. |
| [GitHub](github.md)                           | Import from either GitHub.com or GitHub Enterprise. |
| [GitLab export](../settings/import_export.md) | Migrate projects one by one by using a GitLab export file. |
| [Manifest file](manifest.md)                  | Upload a manifest file. |
| [Repository by URL](repo_by_url.md)           | Provide a Git repository URL to create a new project from. |

After you start a migration, you should not make any changes to imported groups or projects
on the source instance because these changes might not be copied to the destination instance.

### Disable unused import sources

Only import projects from sources you trust. If you import a project from an untrusted source,
an attacker could steal your sensitive data. For example, an imported project
with a malicious `.gitlab-ci.yml` file could allow an attacker to exfiltrate group CI/CD variables.

GitLab Self-Managed administrators can reduce their attack surface by disabling import sources they don't need:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Import and export settings**.
1. Scroll to **Import sources**.
1. Clear checkboxes for importers that are not required.

## Other import sources

You can also read information on importing from these other import sources:

- [ClearCase](clearcase.md)
- [Concurrent Versions System (CVS)](cvs.md)
- [Jira (issues only)](jira.md)
- [Perforce Helix](perforce.md)
- [Team Foundation Version Control (TFVC)](tfvc.md)

### Import repositories from Subversion

GitLab can not automatically migrate Subversion repositories to Git. Converting Subversion repositories to Git can be
difficult, but several tools exist including:

- [`git svn`](https://git-scm.com/book/en/v2/Git-and-Other-Systems-Migrating-to-Git), for very small and basic repositories.
- [`reposurgeon`](http://www.catb.org/~esr/reposurgeon/repository-editing.html), for larger and more complex repositories.

## User contribution and membership mapping

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/443557) in GitLab 17.4 for direct transfer [with flags](../../../administration/feature_flags/_index.md) named `importer_user_mapping` and `bulk_import_importer_user_mapping`. Disabled by default.
- Introduced in GitLab 17.6 for [Gitea](https://gitlab.com/gitlab-org/gitlab/-/issues/467084) [with flags](../../../administration/feature_flags/_index.md) named `importer_user_mapping` and `gitea_user_mapping`, and for [GitHub](https://gitlab.com/gitlab-org/gitlab/-/issues/466355) with flags named `importer_user_mapping` and `github_user_mapping`. Disabled by default.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/466356) in GitLab 17.7 for Bitbucket Server [with flags](../../../administration/feature_flags/_index.md) named `importer_user_mapping` and `bitbucket_server_user_mapping`. Disabled by default.
- [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/472735) in GitLab 17.7 for direct transfer.
- Enabled on GitLab.com in GitLab 17.7 for [Bitbucket Server](https://gitlab.com/gitlab-org/gitlab/-/issues/509897), [Gitea](https://gitlab.com/gitlab-org/gitlab/-/issues/498390), and [GitHub](https://gitlab.com/gitlab-org/gitlab/-/issues/499993).
- Enabled on GitLab Self-Managed in GitLab 17.8 for [Bitbucket Server](https://gitlab.com/gitlab-org/gitlab/-/issues/509897), [Gitea](https://gitlab.com/gitlab-org/gitlab/-/issues/498390), and [GitHub](https://gitlab.com/gitlab-org/gitlab/-/issues/499993).
- Reassigning contributions to a personal namespace owner when importing to a personal namespace [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/525342) in GitLab 18.3 [with a flag](../../../administration/feature_flags/_index.md) named `user_mapping_to_personal_namespace_owner`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by feature flags.
For more information, see the history.

{{< /alert >}}

{{< alert type="note" >}}

To leave feedback about this feature, add a comment to [issue 502565](https://gitlab.com/gitlab-org/gitlab/-/issues/502565).

{{< /alert >}}

This method of user contribution and membership mapping is available by default for
[direct transfer](../../group/import/_index.md), [GitHub importer](github.md),
[Bitbucket Server importer](bitbucket_server.md), and [Gitea importer](gitea.md) on
GitLab.com and GitLab Self-Managed.
For information on the other method available for GitLab Self-Managed with disabled feature flags,
see the documentation for each importer.

Any memberships and contributions you import are first mapped to [placeholder users](#placeholder-users).
These placeholders are created on the destination instance even if
users with the same email addresses exist on the source instance.
Until you reassign contributions on the destination instance,
all contributions display as associated with placeholders.

{{< alert type="note" >}}

Contributions from a deleted user on the source instance are
mapped automatically to that user on the destination instance.

{{< /alert >}}

After the import has completed, you can:

- Reassign memberships and contributions to existing users on the destination instance
  after you review the results.
  You can map memberships and contributions for users with different email addresses
  on source and destination instances.
- Create new users on the destination instance to reassign memberships and contributions to.

When you reassign contributions to a user on the destination instance, the user can
[accept](#accept-contribution-reassignment) or [reject](#reject-contribution-reassignment) the reassignment.
When the user accepts the reassignment:

- Contributions are reassigned. This process might take a few minutes.
- In subsequent imports from the same source instance to the same top-level group or subgroup
  on the destination instance, contributions are mapped automatically to the user.

[In GitLab 18.0 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/510673), if your top-level group
has at least one [enterprise user](../../enterprise_user/_index.md), you can reassign contributions
only to enterprise users in your organization in the UI or by using a CSV file.
This feature is meant to prevent accidental reassignment to users outside your organization.

{{< alert type="note" >}}

When you use a supported method to import projects to a
[personal namespace](../../namespace/_index.md#types-of-namespaces),
user contribution mapping is not supported.
When you import to a personal namespace and the `user_mapping_to_personal_namespace_owner` feature flag
is enabled, all contributions are assigned to the personal namespace owner and they cannot be reassigned.
When the `user_mapping_to_personal_namespace_owner` feature flag is disabled, all contributions are
assigned to a single non-functional user called `Import User` and they cannot be reassigned.

{{< /alert >}}

### Requirements

- You must be able to create enough users, subject to [user limits](#placeholder-user-limits).
- If you import to GitLab.com, you must set up your paid namespace before the import.
- If you import to GitLab.com and use [SAML SSO for GitLab.com groups](../../group/saml_sso/_index.md),
  all users must link their SAML identity to their GitLab.com account before you can
  [reassign contributions and memberships](#reassign-contributions-and-memberships).

### Placeholder users

Instead of immediately assigning contributions and memberships to users on the destination instance, a
placeholder user is created for any active, inactive, or bot user with imported contributions or memberships.
For deleted users on the source instance, placeholders are created
without all [placeholder user attributes](#placeholder-user-attributes).
You should [keep these users as placeholders](#keep-as-placeholder).
For more information, see [issue 506432](https://gitlab.com/gitlab-org/gitlab/-/issues/506432).

Both contributions and memberships are first assigned to these placeholder users and can be reassigned after import
to existing users on the destination instance.
Until they are reassigned, contributions display as associated with the placeholder. Placeholder memberships
do not display in member lists.

Placeholder users do not count towards license limits.

#### Exceptions

A placeholder user is created for each user on the source instance, except in the following scenarios:

- You're importing a project from [Gitea](gitea.md), and the user was deleted on Gitea before the import.
  Contributions from these users are mapped to the user who imported the project, not to a placeholder user.
- You have exceeded your [placeholder user limit](#placeholder-user-limits). Contributions from any new users after exceeding your limit are
  mapped to a single non-functional user called `Import User`.
- You're importing to a [personal namespace](../../namespace/_index.md#types-of-namespaces)
  and the `user_mapping_to_personal_namespace_owner` feature flag is enabled.
  Contributions are assigned to the personal namespace owner.
  When the `user_mapping_to_personal_namespace_owner` is disabled,
  contributions are assigned to a single non-functional user called `Import User`.

#### Placeholder user attributes

Placeholder users are different to regular users and cannot:

- Sign in.
- Perform any actions. For example, running pipelines.
- Appear in suggestions as assignees or reviewers for issues and merge requests.
- Be members of projects and groups.

To maintain a connection with a user on a source instance, placeholder users have:

- A unique identifier (`source_user_id`) used by the import process to determine if a new placeholder user is required.
- A source hostname or domain (`source_hostname`).
- A source user's name (`source_name`) to help with reassignment of contributions.
- A source user's username (`source_username`) to facilitate group owners during the reassignment of the contribution.
- An import type (`import_type`) to distinguish which importer created the placeholder.
- A timestamp of when the source user was created (`created_at`) in local time for migration tracking
  ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/507297) in GitLab 17.10).

To preserve historical context, the placeholder user name and username are derived from the source user name and username:

- Placeholder user's name is `Placeholder <source user name>`.
- Placeholder user's username is `%{source_username}_placeholder_user_%{incremental_number}`.

#### View placeholder users

Prerequisites:

- You must have the Owner role for the group.

Placeholder users are created on the destination instance while a group or project is imported.
To view placeholder users created during imports to a top-level group and its subgroups:

1. On the left sidebar, select **Search or go to** and find your group.
   This group must be at the top level.
1. Select **Manage > Members**.
1. Select the **Placeholders** tab.

#### Filter for placeholder users

{{< details >}}

- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/521974) in GitLab 17.11.

{{< /history >}}

Prerequisites:

- You must have administrator access to the instance.

Placeholder users are created on the destination instance while a group or project is imported.
To filter for placeholder users created during imports for an entire instance:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. In the search box, filter users by **type**.

#### Creating placeholder users

Placeholder users are created per [import source](#supported-import-sources) and per top-level group:

- If you import the same project twice to the same top-level group on the destination instance, the second import uses
  the same placeholder users as the first import.
- If you import the same project twice, but to a different top-level group on the destination instance, the second import
  creates new placeholder users under that top-level group.

{{< alert type="note" >}}

Placeholder users are associated only with the top-level group.
When you delete a subgroup or project, their placeholder users
no longer reference any contributions in the top-level group.
For testing, you should use a designated top-level group.
Deleting placeholder users is proposed in [issue 519391](https://gitlab.com/gitlab-org/gitlab/-/issues/519391)
and [issue 537340](https://gitlab.com/gitlab-org/gitlab/-/issues/537340).

{{< /alert >}}

When a user [accepts the reassignment](#accept-contribution-reassignment),
subsequent imports from the same source instance to the same top-level group or
subgroup on the destination instance do not create placeholder users.
Instead, contributions are mapped automatically to the user.

#### Placeholder user deletion

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/473256) in GitLab 18.0.

{{< /history >}}

When you delete a top-level group that contains placeholder users,
these users are automatically scheduled for removal.
This process might take some time to complete.
However, placeholder users remain in the system if
they're also associated with other projects or groups.

{{< alert type="note" >}}

There is no other way to delete placeholder users, but support for improvements is proposed in
[issue 519391](https://gitlab.com/gitlab-org/gitlab/-/issues/519391) and
[issue 537340](https://gitlab.com/gitlab-org/gitlab/-/issues/537340).

{{< /alert >}}

#### Placeholder user limits

If importing to GitLab.com, placeholder users are limited per top-level group on the destination instance. The limits differ depending on your plan and seat count. Placeholder users do not count towards license limits.

| GitLab.com plan          | Number of seats | Placeholder user limit on top-level group |
|:-------------------------|:----------------|:------------------------------------------|
| Free and any trial       | Any amount      | 200                                       |
| Premium                  | < 100           | 500                                       |
| Premium                  | 101-500         | 2000                                      |
| Premium                  | 501 - 1000      | 4000                                      |
| Premium                  | > 1000          | 6000                                      |
| Ultimate and open source | < 100           | 1000                                      |
| Ultimate and open source | 101-500         | 4000                                      |
| Ultimate and open source | 501 - 1000      | 6000                                      |
| Ultimate and open source | > 1000          | 8000                                      |

For GitLab Self-Managed and GitLab Dedicated, no placeholder limits apply by default.
A GitLab administrator can [set a placeholder limit](../../../administration/instance_limits.md#import-placeholder-user-limits) on their instance.

To view your current placeholder user usage and limits:

1. On the left sidebar, select **Search or go to** and
   find your group. This group must be at the top level.
1. Select **Settings > Usage quotas**.
1. Select the **Import** tab.

You cannot determine the number of placeholder users you need in advance.

When the placeholder user limit is reached, all contributions
are assigned to a single non-functional user called `Import User`.
Contributions assigned to `Import User` might be deduplicated,
and some contributions might not be created during the import.
For example, if multiple approvals from a merge request approver are assigned
to `Import User`, only the first approval is created and the others are ignored.
The contributions that might be deduplicated are:

- Approval rules
- Emoji reactions
- Issue assignees
- Memberships
- Merge request approvals, assignees, and reviewers
- Push, merge request, and deploy access levels

Every change creates a system note, which is not affected by the placeholder user limit.

### Reassign contributions and memberships

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

### Bypass confirmation when reassigning placeholder users

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/17871) in GitLab 18.3 [with a flag](../../../administration/feature_flags/list.md) named `group_owner_placeholder_confirmation_bypass`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

Prerequisites:

- You must have the Owner role for the group.

To bypass confirmation for [enterprise users](../../enterprise_user/_index.md)
when you reassign placeholders:

1. On the left sidebar, select **Search or go to** and find your group.
   This group must be at the top level.
1. Select **Settings** > **General**.
1. Expand **Permissions and group features**.
1. Under **Placeholder user confirmation**, select the
   **Reassign placeholders to enterprise users without user confirmation** checkbox.
1. In **When to restore user confirmation**,
   select an end date for bypassing user confirmation.
   The default value is one day.
1. Select **Save changes**.

#### Reassigning contributions from multiple placeholder users

All the contributions initially assigned to a single placeholder user can only be reassigned to a single active regular
user on the destination instance. The contributions assigned to a single placeholder user cannot be split among multiple
active regular users.

You can reassign contributions from multiple placeholder users to the same user
on the destination instance if the placeholder users are from:

- Different source instances
- The same source instance and are imported to different top-level groups on the destination instance

If an assigned user becomes inactive before accepting the reassignment request,
the pending reassignment remains linked to the user until they accept it.

Bot user contributions and memberships on the source instance cannot be reassigned to bot users on the destination instance.
You might choose to keep source bot user contributions [assigned to a placeholder user](#keep-as-placeholder).

Users that receive a reassignment request can:

- [Accept the request](#accept-contribution-reassignment). All contributions and membership previously attributed to the placeholder user are re-attributed
  to the accepting user. This process can take a few minutes, depending on the number of contributions.
- [Reject the request](#reject-contribution-reassignment) or report it as spam. This option is available in the reassignment
  request email.

In subsequent imports to the same top-level group, contributions and memberships that belong to the same source user
are mapped automatically to the user who previously accepted reassignments for that source user.

On GitLab Self-Managed and GitLab Dedicated, administrators can reassign
contributions and memberships to active and inactive non-bot users immediately without their confirmation.
For more information, see [skip confirmation when administrators reassign placeholder users](../../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users).

#### Completing the reassignment

The reassignment process must be fully completed before you:

- [Move an imported group in the same GitLab instance](../../group/manage.md#transfer-a-group).
- [Move an imported project to a different group](../settings/migrate_projects.md).
- Duplicate an imported issue.
- Promote an imported issue to an epic.

If the process isn't complete, contributions still assigned to placeholder users cannot be reassigned to real users and
they stay associated with placeholder users.

#### Security considerations

Contribution and membership reassignment cannot be undone, so check everything carefully before you start.

Reassigning contributions and membership to an incorrect user poses a security threat, because the user becomes a member
of your group. They can, therefore, view information they should not be able to see.

Reassigning contributions to users with administrator access is disabled by default, but you can
[enable](../../../administration/settings/import_and_export_settings.md#allow-contribution-mapping-to-administrators) it.

##### Membership security considerations

Because of the GitLab permissions model, when a group or project is imported into an existing parent group, members of
the parent group are granted [inherited membership](../members/_index.md#membership-types) of the imported group or project.

Selecting a user for contribution and membership reassignment who already has an
existing inherited membership of the imported group or project can affect how memberships
are reassigned to them.

GitLab does not allow a membership in a child project or group to have a lower role
than an inherited membership. If an imported membership for an assigned user has a lower role
than their existing inherited membership, the imported membership is not reassigned to the user.

This results in their membership for the imported group or project being higher than it was on the source.

#### Request reassignment in UI

Prerequisites:

- You must have the Owner role for the group.

You can reassign contributions and memberships in the top-level group.
To request reassignment of contributions and memberships:

1. On the left sidebar, select **Search or go to** and find your group.
   This group must be at the top level.
1. Select **Manage > Members**.
1. Select the **Placeholders** tab.
1. Go to **Awaiting reassignment** sub-tab, where placeholders are listed in a table.
1. For each placeholder, review information in table columns **Placeholder user** and **Source**.
1. In the **Reassign placeholder to** column, select the a user from the dropdown list.
1. Select **Reassign**.

Contributions of only one placeholder user can be reassigned to an active non-bot user on destination instance.

Before a user accepts the reassignment, you can [cancel the request](#cancel-reassignment-request).

On GitLab Self-Managed and GitLab Dedicated, administrators can reassign
contributions and memberships to active and inactive non-bot users immediately without their confirmation.
For more information, see [skip confirmation when administrators reassign placeholder users](../../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users).

#### Request reassignment by using a CSV file

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
| `gitlab.example.com` | `gitlab`    | `alice`                | `Alice Coder`    | `a.coer`        |

Do not update **Source host**, **Import type**, or **Source user identifier**.
This information locates the corresponding database record
after you've uploaded the completed CSV file.
**Source user name** and **Source username** identify the source user
and are not used after you've uploaded the CSV file.

You do not have to update every row of the CSV file.
Only rows with **GitLab username** or **GitLab public email** are processed.
All other rows are skipped.

To request reassignment of contributions and memberships by using a CSV file:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Manage > Members**.
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

After you reassign contributions, GitLab sends you an email with the number of:

- Successfully processed rows
- Unsuccessfully processed rows
- Skipped rows

If any rows have not been successfully processed, the email has a CSV file with more detailed results.

To reassign placeholder users in bulk without using the UI,
see [Group placeholder reassignments API](../../../api/group_placeholder_reassignments.md).

#### Keep as placeholder

You might not want to reassign contributions and memberships to users on the destination instance. For example, you
might have former employees that contributed on the source instance, but they do not exist as users on the destination
instance.

In these cases, you can keep the contributions assigned to placeholder users. Placeholder users do not keep
membership information because they [cannot be members of projects or groups](#placeholder-user-attributes).

Because names and usernames of placeholder users resemble names and usernames of source users, you keep a lot of
historical context.

Remember that if you keep remaining placeholder users as placeholders, you cannot reassign their contributions to
actual users later. Ensure all required reassignments are completed before keeping the remaining placeholder users as
placeholders.

You can keep contributions assigned to placeholder users either one at a time or in bulk.
When you reassign contributions in bulk, the entire namespace and users with the following
[reassignment statuses](#view-and-filter-by-reassignment-status) are affected:

- `Not started`
- `Rejected`

To keep placeholder users one at a time:

1. On the left sidebar, select **Search or go to** and find your group.
   This group must be at the top level.
1. Select **Manage > Members**.
1. Select the **Placeholders** tab.
1. Go to **Awaiting reassignment** sub-tab, where placeholders are listed in a table.
1. Find placeholder user you want to keep by reviewing **Placeholder user** and **Source** columns.
1. In **Reassign placeholder to** column, select **Do not reassign**.
1. Select **Confirm**.

To keep placeholder users in bulk:

1. On the left sidebar, select **Search or go to** and find your group.
   This group must be at the top level.
1. Select **Manage > Members**.
1. Select the **Placeholders** tab.
1. Above the list, select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Keep all as placeholders**.
1. On the confirmation dialog, select **Confirm**.

#### Cancel reassignment request

Before a user accepts a reassignment request, you can cancel the request:

1. On the left sidebar, select **Search or go to** and find your group.
   This group must be at the top level.
1. Select **Manage > Members**.
1. Select the **Placeholders** tab.
1. Go to **Awaiting reassignment** sub-tab, where placeholders are listed in a table.
1. Select **Cancel** in the correct row.

#### Notify user again about pending reassignment requests

If a user is not acting on a reassignment request, you can prompt them again by sending another email:

1. On the left sidebar, select **Search or go to** and find your group.
   This group must be at the top level.
1. Select **Manage > Members**.
1. Select the **Placeholders** tab.
1. Go to **Awaiting reassignment** sub-tab, where placeholders are listed in a table.
1. Select **Notify** in the correct row.

#### View and filter by reassignment status

To view the reassignment status of all placeholder users:

1. On the left sidebar, select **Search or go to** and find your group.
   This group must be at the top level.
1. Select **Manage > Members**.
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

### Confirm contribution reassignment

When [**Skip confirmation when administrators reassign placeholder users**](../../../administration/settings/import_and_export_settings.md#skip-confirmation-when-administrators-reassign-placeholder-users) is enabled:

- Administrators can reassign contributions immediately without user confirmation.
- Administrators can reassign contributions to active and inactive non-bot users.
- You receive an email informing you that you've been reassigned contributions.

If this setting is not enabled, you can [accept](#accept-contribution-reassignment)
or [reject](#reject-contribution-reassignment) the reassignment.

#### Accept contribution reassignment

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

#### Reject contribution reassignment

If you receive an email asking you to confirm reassignment of contributions to yourself and you don't recognize or you
notice mistakes in this information:

1. Do not proceed at all or reject the contribution reassignment.
1. Talk to a trusted colleague or your manager.

#### Security considerations

You must review the reassignment details of any reassignment request very carefully. If you were not already informed
about this process by a trusted colleague or your manager, take extra care.

Rather than accept any reassignments that you have any doubts about:

1. Don't act on the emails.
1. Talk to a trusted colleague or your manager.

Accept reassignments only from the users that you know and trust. Reassignment of contributions is permanent and cannot
be undone. Accepting the reassignment might cause contributions to be incorrectly attributed to you.

The contribution reassignment process starts only after you accept the reassignment request by selecting
**Approve reassignment** in GitLab. The process doesn't start by selecting links in the email.

## View project import history

You can view all project imports created by you. This list includes the following:

- Paths of source projects if projects were imported from external systems, or import method if GitLab projects were migrated.
- Paths of destination projects.
- Start date of each import.
- Status of each import.
- Error details if any errors occurred.

To view project import history:

1. Sign in to GitLab.
1. On the left sidebar, at the top, select **Create new** ({{< icon name="plus" >}}) and **New project/repository**.
1. Select **Import project**.
1. In the upper-right corner, select the **History** link.
1. If there are any errors for a particular import, select **Details** to see them.

The history also includes projects created from [built-in](../_index.md#create-a-project-from-a-built-in-template)
or [custom](../_index.md#create-a-project-from-a-custom-template)
templates. GitLab uses [import repository by URL](repo_by_url.md)
to create a new project from a template.

## Importing projects with LFS objects

When importing a project that contains LFS objects, if the project has an [`.lfsconfig`](https://github.com/git-lfs/git-lfs/blob/main/docs/man/git-lfs-config.adoc)
file with a URL host (`lfs.url`) different from the repository URL host, LFS files are not downloaded.

## Migrate by engaging Professional Services

If you prefer, you can engage GitLab Professional Services to migrate groups and projects to GitLab instead of doing it
yourself. For more information, see the [Professional Services Full Catalog](https://about.gitlab.com/services/catalog/).

## Sidekiq configuration

Importers rely heavily on Sidekiq jobs to handle the import and export of groups and projects.
Some of these jobs might consume significant resources (CPU and memory) and
take a long time to complete, which might affect the execution of other jobs.
To resolve this issue, you should route importer jobs to a dedicated Sidekiq queue and
assign a dedicated Sidekiq process to handle that queue.

For example, you can use the following configuration:

```conf
sidekiq['concurrency'] = 20

sidekiq['routing_rules'] = [
  # Route import and export jobs to the importer queue
  ['feature_category=importers', 'importers'],

  # Route all other jobs to the default queue by using wildcard matching
  ['*', 'default']
]

sidekiq['queue_groups'] = [
  # Run a dedicated process for the importer queue
  'importers',

  # Run a separate process for the default and mailer queues
  'default,mailers'
]
```

In this setup:

- A dedicated Sidekiq process handles import and export jobs through the importer queue.
- Another Sidekiq process handles all other jobs (the default and mailer queues).
- Both Sidekiq processes are configured to run with 20 concurrent threads by default.
  For memory-constrained environments, you might want to reduce this number.

If your instance has enough resources to support more concurrent jobs,
you can configure additional Sidekiq processes to speed up migrations.
For example:

```conf
sidekiq['queue_groups'] = [
  # Run three processes for importer jobs
  'importers',
  'importers',
  'importers',

  # Run a separate process for the default and mailer queues
  'default,mailers'
]
```

With this setup, multiple Sidekiq processes handle import and export jobs concurrently,
which speeds up migration as long as the instance has sufficient resources.

For the maximum number of Sidekiq processes, keep the following in mind:

- The number of processes should not exceed the number of available CPU cores.
- Each process can use up to 2 GB of memory, so ensure the instance
  has enough memory for any additional processes.
- Each process adds one database connection per thread
  as defined in `sidekiq['concurrency']`.

For more information, see [running multiple Sidekiq processes](../../../administration/sidekiq/extra_sidekiq_processes.md)
and [processing specific job classes](../../../administration/sidekiq/processing_specific_job_classes.md).

## Troubleshooting

### Imported repository is missing branches

If an imported repository does not contain all branches of the source repository:

1. Set the [environment variable](../../../administration/logs/_index.md#override-default-log-level) `IMPORT_DEBUG=true`.
1. Retry the import with a [different group, subgroup, or project name](https://about.gitlab.com/releases/2023/02/22/gitlab-15-9-released/#re-import-projects-from-external-providers).
1. If some branches are still missing, inspect [`importer.log`](../../../administration/logs/_index.md#importerlog)
   (for example, with [`jq`](../../../administration/logs/log_parsing.md#parsing-gitlab-railsimporterlog)).

### Exception: `Error Importing repository - No such file or directory @ rb_sysopen - (filename)`

The error occurs if you attempt to import a `tar.gz` file download of a repository's source code.

Imports require a [GitLab export](../settings/import_export.md#export-a-project-and-its-data) file, not just a repository download file.

### Diagnosing prolonged or failed imports

If you're experiencing prolonged delays or failures with file-based imports, especially those using S3, the following may help identify the root cause of the problem:

- [Check import steps](#check-import-status)
- [Review logs](#review-logs)
- [Identify common issues](#identify-common-issues)

#### Check import status

Check the import status:

1. Use the GitLab API to check the [import status](../../../api/project_import_export.md#import-status) of the affected project.
1. Review the response for any error messages or status information, especially the `status` and `import_error` values.
1. Make note of the `correlation_id` in the response, as it's crucial for further troubleshooting.

#### Review logs

Search logs for relevant information:

For GitLab Self-Managed instances:

1. Check the [Sidekiq logs](../../../administration/logs/_index.md#sidekiqlog) and [`exceptions_json` logs](../../../administration/logs/_index.md#exceptions_jsonlog).
1. Search for entries related to `RepositoryImportWorker` and the correlation ID from [Check import status](#check-import-status).
1. Look for fields such as `job_status`, `interrupted_count`, and `exception`.

For GitLab.com (GitLab team members only):

1. Use [Kibana](https://log.gprd.gitlab.net/) to search the Sidekiq logs with queries like:

   Target: `pubsub-sidekiq-inf-gprd*`

   ```plaintext
   json.class: "RepositoryImportWorker" AND json.correlation_id.keyword: "<CORRELATION_ID>"
   ```

   or

   ```plaintext
   json.class: "RepositoryImportWorker" AND json.meta.project: "<project.full_path>"
   ```

1. Look for the same fields as mentioned for GitLab Self-Managed instances.

#### Identify common issues

Check the information gathered in [Review logs](#review-logs) against the following common issues:

- **Interrupted jobs**: If you see a high `interrupted_count` or `job_status` indicating failure, the import job may have been interrupted multiple times and placed in a dead queue.
- **S3 connectivity**: For imports using S3, check for any S3-related error messages in the logs.
- **Large repository**: If the repository is very large, the import might time out. Consider using [Direct transfer](../../group/import/_index.md) in this case.
