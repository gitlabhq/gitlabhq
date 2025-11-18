---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: External users
description: Grant limited access to external members with restricted permissions for specific resources.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

External users have limited access to internal or private groups and projects in the instance. Unlike regular users, external users must be explicitly added to a group or project. However, like regular users, external users are assigned a member role and gain all the associated [permissions](../user/permissions.md#project-members-permissions).

External users:

- Can access public groups, projects, and snippets.
- Can access internal or private groups and projects where they are members.
- Can create subgroups, projects, and snippets in any top-level groups where they are members.
- Cannot create groups, projects, or snippets in their personal namespace.

External users are commonly created when a user outside an organization needs access to only a
specific project. When assigning a role to an external user, you should be aware of the
[project visibility](../user/public_access.md#change-project-visibility) and
[permissions](../user/project/settings/_index.md#configure-project-features-and-permissions)
associated with the role. For example, if an external user is assigned the Guest role for a
private project, they cannot access the code.

{{< alert type="note" >}}

An external user counts as a billable user and consumes a license seat.

{{< /alert >}}

## Create an external user

To create a new external user:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Overview** > **Users**.
1. Select **New user**.
1. In the **Account** section, enter the required account information.
1. Optional. In the **Access** section, configure any project limits or user type settings.
1. Select the **External** checkbox.
1. Select **Create user**.

You can also create external users with:

- [SAML groups](../integration/saml.md#external-groups).
- [LDAP groups](auth/ldap/ldap_synchronization.md#external-groups).
- The [External providers list](../integration/omniauth.md#create-an-external-providers-list).
- The [users API](../api/users.md).

## Make new users external by default

You can configure your instance to make all new users external by default. You can modify these user
accounts later to remove the external designation.

When you configure this feature, you can also define a regular expression used to identify email
addresses. New users with a matching email are excluded and not marked as an external user. This
regular expression must:

- Use the Ruby format.
- Be convertible to JavaScript.
- Have the ignore case flag set (`/regex pattern/i`).

For example:

- `\.int@example\.com$`: Matches email addresses that end with `.int@domain.com`.
- `^(?:(?!\.ext@example\.com).)*$\r?`: Matches email address that don't include `.ext@example.com`.

{{< alert type="warning" >}}

Adding an regular expression can increase the risk of a regular expression denial of service (ReDoS) attack.

{{< /alert >}}

Prerequisites:

- You must be an administrator for the GitLab Self-Managed instance.

To make new users external by default:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../user/interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Settings** > **General**.
1. Expand the **Account and limit** section.
1. Select the **Make new users external by default** checkbox.
1. Optional. In the **Email exclusion pattern** field, enter a regular expression.
1. Select **Save changes**.
