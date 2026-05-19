---
stage: Create
group: Import
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Post-migration contribution and membership mapping
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/443557) in GitLab 17.4 for direct transfer [with flags](../../../administration/feature_flags/_index.md) named `importer_user_mapping` and `bulk_import_importer_user_mapping`. Disabled by default.
- Introduced in GitLab 17.6 for [Gitea](https://gitlab.com/gitlab-org/gitlab/-/issues/467084) [with flags](../../../administration/feature_flags/_index.md) named `importer_user_mapping` and `gitea_user_mapping`, and for [GitHub](https://gitlab.com/gitlab-org/gitlab/-/issues/466355) with flags named `importer_user_mapping` and `github_user_mapping`. Disabled by default.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/466356) in GitLab 17.7 for Bitbucket Server [with flags](../../../administration/feature_flags/_index.md) named `importer_user_mapping` and `bitbucket_server_user_mapping`. Disabled by default.
- [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/472735) in GitLab 17.7 for direct transfer.
- Enabled on GitLab.com in GitLab 17.7 for [Bitbucket Server](https://gitlab.com/gitlab-org/gitlab/-/issues/509897), [Gitea](https://gitlab.com/gitlab-org/gitlab/-/issues/498390), and [GitHub](https://gitlab.com/gitlab-org/gitlab/-/issues/499993).
- Enabled on GitLab Self-Managed in GitLab 17.8 for [Bitbucket Server](https://gitlab.com/gitlab-org/gitlab/-/issues/509897), [Gitea](https://gitlab.com/gitlab-org/gitlab/-/issues/498390), and [GitHub](https://gitlab.com/gitlab-org/gitlab/-/issues/499993).
- Reassigning contributions to a personal namespace owner when importing to a personal namespace [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/525342) in GitLab 18.3 [with a flag](../../../administration/feature_flags/_index.md) named `user_mapping_to_personal_namespace_owner`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/508945) in GitLab 18.4 for direct transfer. Feature flag `bulk_import_importer_user_mapping` removed.
- Reassigning contributions to service accounts, project bots, and group
  bots [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/573124) in GitLab
  18.5 [with a flag](../../../administration/feature_flags/_index.md) named `user_mapping_service_account_and_bots`.
  Enabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/512211) in GitLab 18.6 for Gitea. Feature flag
  `gitea_user_mapping` removed.
- Reassigning contributions to a personal namespace owner when importing to a personal namespace [generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/211626) in GitLab 18.6. Feature flag `user_mapping_to_personal_namespace_owner` removed.
- `github_user_mapping` feature flag [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216778) in GitLab 18.8.
- `user_mapping_service_account_and_bots` feature flag [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/223142) in GitLab 18.10.

{{< /history >}}

With post-migration mapping, user contributions and memberships from source instances are initially assigned to
placeholder users rather than real users on the destination instance.

Because you can defer assigning to real users, you have time to review the import and reassign contributions to the
correct users. This process ensures accurate attribution while maintaining control over the mapping process.

Post-migration user contribution and membership mapping is available by default for migrations from:

- [GitLab when using direct transfer](../../group/import/_index.md)
- [GitHub](../../project/import/github.md)
- [Bitbucket Server](../bitbucket_server.md)
- [Gitea](../gitea.md)

When you import projects to a [personal namespace](../../namespace/_index.md#types-of-namespaces), user contribution mapping
and membership mapping is not supported and all contributions are assigned to the personal namespace owner. These
contributions cannot be reassigned.

## Prerequisites

- Plan for the number of users, according to the [user limits](#placeholder-user-limits).
- If you import to GitLab.com, set up your paid namespace.
- If you import to GitLab.com and use [SAML SSO for GitLab.com groups](../../group/saml_sso/_index.md),
  ensure all users link their SAML identity to their GitLab.com account.

## Post-migration mapping workflow

When using post-migration mapping, GitLab maps any memberships and contributions you import to
[placeholder users](#placeholder-users). Placeholder users are created on the destination instance even if users with
the same email addresses exist on the destination instance. Until you reassign contributions on the
destination instance, all contributions are associated with placeholder users.

After the import is complete and you've reviewed the results, you can update the mappings as follows:

- Reassign memberships and contributions to existing users on the destination instance.
  You can map memberships and contributions for users with different email addresses on source and destination instances.
- Create new users on the destination instance and reassign memberships and contributions to them.

You can also keep certain contributions assigned to placeholder users to preserve historical context.

When you reassign contributions to a user on the destination instance, the user can either:

- Accept the reassignment. The reassignment process might take a few minutes. In subsequent imports from the same source
  instance to the same top-level group or subgroup on the destination instance, contributions are mapped automatically
  to the user.
- Reject the reassignment.

## Enterprise users

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/510673) in GitLab 18.0.

{{< /history >}}

If your top-level group has at least one [enterprise user](../../enterprise_user/_index.md), you can reassign contributions
only to enterprise users in your organization.

This means you cannot accidentally reassign to users outside your organization.

## Deleted users

Contributions on the source instance that were made by a now deleted user are mapped on the destination instance to
[a ghost user](../../../administration/internal_users.md), except when:

- The contribution was never properly detached from the deleted user on the source instance.
- Migrating from Bitbucket Server.

## Placeholder users

With contribution and membership mapping, you don't immediately assign contributions and memberships to users on the
destination instance. Instead, a placeholder user is created for any active, inactive, or bot user with imported
contributions or memberships.

Both contributions and memberships are initially assigned to these placeholder users and can be reassigned after import
to existing users on the destination instance.

Until they are reassigned, contributions are associated with the placeholder. Placeholder memberships do not display in
member lists.

Placeholder users do not count towards license limits.

### Exceptions

A placeholder user is not created in these scenarios:

- You're importing a project from [Gitea](../gitea.md) with contributions from deleted users.
  Contributions from these users are mapped to the user who imported the project.
- You have exceeded your [placeholder user limit](#placeholder-user-limits). Contributions from any new users are
  mapped to an import user.

### Placeholder user attributes

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

### View placeholder users

Prerequisites:

- You must have the Owner role for the group.

Placeholder users are created on the destination instance while a group or project is imported.
To view placeholder users created during imports to a top-level group and its subgroups:

1. In the top bar, select **Search or go to** and find your group.
   This group must be at the top level.
1. In the left sidebar, select **Manage** > **Members**.
1. Select the **Placeholders** tab.

### Filter for placeholder users

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

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Overview** > **Users**.
1. In the search box, filter users by **type**.

### Creating placeholder users

Placeholder users are created per import source and per top-level group:

- If you import the same project twice to the same top-level group on the destination instance, the second import uses
  the same placeholder users as the first import.
- If you import the same project twice, but to a different top-level group on the destination instance, the second import
  creates new placeholder users under that top-level group.

> [!note]
> Placeholder users are associated only with the top-level group.
> When you delete a subgroup or project, their placeholder users
> no longer reference any contributions in the top-level group.
> For testing, you should use a designated top-level group.
> Deleting placeholder users is proposed in [issue 519391](https://gitlab.com/gitlab-org/gitlab/-/issues/519391)
> and [issue 537340](https://gitlab.com/gitlab-org/gitlab/-/issues/537340).

When a user [accepts the reassignment](reassignment.md#accept-contribution-reassignment),
subsequent imports from the same source instance to the same top-level group or
subgroup on the destination instance do not create placeholder users.
Instead, contributions are mapped automatically to the user.

### Placeholder user deletion

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/473256) in GitLab 18.0.

{{< /history >}}

When you delete a top-level group that contains placeholder users,
these users are automatically scheduled for removal.
This process might take some time to complete.
However, placeholder users remain in the system if
they're also associated with other projects or groups.

> [!note]
> There is no other way to delete placeholder users, but support for improvements is proposed in
> [issue 519391](https://gitlab.com/gitlab-org/gitlab/-/issues/519391) and
> [issue 537340](https://gitlab.com/gitlab-org/gitlab/-/issues/537340).

### Placeholder user limits

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

1. In the top bar, select **Search or go to** and find your group. This group must be at the top level.
1. Select **Settings** > **Usage quotas**.
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

## Alternative mapping method

An alternative to post-migration mapping is a method that maps during a migration.
This method is not recommended, and any problems found are unlikely to be fixed.

The alternative method of mapping:

- Is available only for migrations to GitLab Self-Managed.
- Requires some preparation before migration, including disabling applicable `*_user_mapping` feature flags.
- Is available for migrations from:
  - GitHub.
  - Bitbucket Server.
  - Gitea (for GitLab 18.5 and earlier).

For more information, see the alternative method of mapping documentation for each importer.
