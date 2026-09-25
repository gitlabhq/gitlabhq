---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Organizations
description: Namespace hierarchy.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

> [!flag]
> The availability of this feature is controlled by feature flags.
> This feature is not ready for production use.

An organization is the top-level entity in the GitLab hierarchy. Each organization
contains one or more [top-level groups](../namespace/_index.md),
and all of their subgroups and projects.

An organization acts as an administration layer above those groups,
with a dedicated admin area where you can administer organization
settings and manage users.

For more information about the state of organization development,
see [epic 9265](https://gitlab.com/groups/gitlab-org/-/epics/9265).

Organizations are in closed beta, and available by invitation only to a limited set of
beta participants.
To request access, contact your GitLab account team.

## Create an organization

Create an organization from an existing top-level group.

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/247436) in GitLab 19.3 [with a feature flag](../../administration/feature_flags/_index.md) named `org_stage_beta`. Disabled by default.

{{< /history >}}

Prerequisites:

- The Owner role for the top-level group you start from,
  and for any other top-level group you want to include.

To create an organization from an existing top-level group:

1. In the top bar, select **Search or go to** and find your group. This group must be at the top level.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **Advanced**.
1. In the **Create an organization** section, select **Create organization**.
1. In the **Create your Organizations** confirmation dialog, select the group you want to create an organization with, then select **Continue**.
1. Optional. If you have the Owner role for multiple top-level groups, in the
   **Assign top-level groups** confirmation dialog, drag those groups into the organization container.
   Groups you do not assign are not included.
   Select **Continue**.
1. In the **Confirm your organization** confirmation dialog, review the proposed structure.
1. Select **Confirm**.

After you confirm your organization structure:

- Your groups and projects transfer into the organization asynchronously.
- Users who are members of a transferred group or project become organization members.
- You receive an email when the transfer is ready. Larger groups take longer to transfer.
- Any user with the Owner role in all of the transferred top-level groups becomes an organization administrator.

You can change the organization name, URL, description, visibility, and avatar later from the organization admin area.

> [!note]
> After you confirm your organization structure, you cannot add or remove top-level groups yourself. If you want to add additional top-level groups to your organization after confirmation, contact support for help.
> You also cannot delete the organization while it holds groups or projects.
> If you must make changes, [contact support](https://support.gitlab.com/).

## Go to your organization

If you are a member of one or more organizations, you can go to any of them from the
**Organizations** page. To access an organization:

1. In the left sidebar, select **Organizations**.
1. From the list, select the organization you want to go to.

## Organization URLs

An organization, and everything it contains, is addressed under `/o/<organization-path>/`.
For example, `https://gitlab.example.com/o/my-org/-/overview`.
Existing group and project URLs keep working.

Because `o` is a reserved path, no top-level group can use `o` as its path.

The default organization is an exception to this URL scheme.
Its content stays on unscoped URLs.

## The default organization

Every GitLab instance has one default organization.
Every account starts in the default organization.
The default organization cannot be deleted.

You leave the default organization when your top-level group moves into an organization of your own.

## User types and permissions

An organization has two user types, organization administrator and organization regular user.

A user type describes a person's relationship to the organization.
For an organization regular user, group and project roles govern access to groups and projects.
Organization administrators have full access to all groups and projects inside the organization.

The following table lists the actions available to each user type:

| Action | Organization administrator | Organization regular user |
|--------|----------------------------|-------------------|
| View the organization | {{< yes >}} | {{< yes >}} |
| Create a group | {{< yes >}} | {{< yes >}} |
| Update the organization | {{< yes >}} | {{< no >}} |
| Access the organization admin area | {{< yes >}} | {{< no >}} |
| Add a user to the organization | {{< yes >}} | {{< no >}} |
| View organization users | {{< yes >}} | {{< no >}} |
| Update an organization user | {{< yes >}} | {{< no >}} |
| Remove a user from the organization | {{< yes >}} | {{< no >}} |
| Transfer a top-level group into the organization | {{< yes >}} | {{< no >}} |
| Delete the organization | {{< yes >}} | {{< no >}} |
| Leave the organization | {{< yes >}} | {{< yes >}} |

Only instance administrators can restore a deleted organization.

Organization administrators can also purchase organization-scoped products, such as the
artifact registry.
After you purchase a product, you can assign product-specific roles to organization users.

### Group and project roles

Inside an organization, [default roles](../permissions.md#default-roles) still control access
to groups and projects.

When a top-level group transfers into an organization, its group and project members
become organization users.
They keep their pre-existing roles and permissions.

## Manage organization users

Use the organization admin area to add organization users, change their user type, and remove them.

Prerequisites:

- You must be an organization administrator.

### View organization users

To view the users in your organization:

1. In the left sidebar, select **Organizations**.
1. From the dropdown list, select the organization you want to go to.
1. In the left sidebar, select **Manage organization**.
1. Select **Organization overview** > **Users**.

### Add a user to an organization

To add a user to an organization:

1. In the left sidebar, select **Organizations**.
1. From the dropdown list, select the organization you want to go to.
1. In the left sidebar, select **Manage organization**.
1. Select **Organization overview** > **Users**.
1. Select **Invite organization user**.
1. In **GitLab usernames**, search for and select one or more users by username.
1. Under **Organization user type**, select one of the following:
   - **Organization regular user**: Grants a user access to groups and projects they are a member of.
   - **Organization administrator**: Grants access to all groups, projects, users, features, and the **Organization Admin** area.
1. Select **Invite**.

You can also add a user to an organization by adding them to a group or project in the organization.

### Change a user's type

To change whether a user is an organization regular user or an organization administrator:

1. In the left sidebar, select **Organizations**.
1. From the dropdown list, select the organization you want to go to.
1. In the left sidebar, select **Manage organization**.
1. Select **Organization overview** > **Users**.
1. Next to the user, select **Edit**.
1. Under **Organization user type**, select one of the following:
   - **Organization regular user**: Grants a user access to groups and projects they are a member of.
   - **Organization administrator**: Grants access to all groups, projects, users, features, and the **Organization Admin** area.
1. Select **Save changes**.

### Remove a user from an organization

When you remove a user from an organization, they are also removed from all groups
and projects in the organization.

To remove a user from an organization:

1. In the left sidebar, select **Organizations**.
1. From the dropdown list, select the organization you want to go to.
1. In the left sidebar, select **Manage organization**.
1. Select **Organization overview** > **Users**.
1. Next to the user, select the vertical ellipsis ({{< icon name="ellipsis_v" >}}) > **Remove from organization**.
1. In the confirmation dialog, select **Remove**.

## Organization visibility

An organization is either public or private.
Internal visibility is not available for organizations.

| Visibility | Who can view the organization | Group and project visibility allowed |
|------------|-------------------------------|--------------------------------------|
| Public | Everyone | Public and private |
| Private | Organization users only | Private |

An organization cannot be more restrictive than the groups it contains.
For example, you cannot make an organization private while it holds a public group.

## Organization deletion

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/599345) in GitLab 19.2.

{{< /history >}}

You can delete an organization only when it contains no groups and no projects, and it is not
the default organization.
GitLab soft-deletes the organization rather than removing it immediately.
Only instance administrators can restore a deleted organization.

To delete an organization, you can also [use the API](../../api/organizations.md).

## Supported Markdown for organization description

The organization description field supports a limited subset of [GitLab Flavored Markdown](../markdown.md), including:

- [Emphasis](../markdown.md#emphasis)
- [Links](../markdown.md#links)
- [Superscripts / Subscripts](../markdown.md#superscripts-and-subscripts)
