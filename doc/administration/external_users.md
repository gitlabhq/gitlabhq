---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: External users
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

In cases where it is desired that a user has access only to some internal or
private projects, there is the option of creating **External Users**. This
feature may be useful when for example a contractor is working on a given
project and should only have access to that project.

External users:

- Cannot create project, groups, and snippets in their personal namespaces.
- Can only create projects (including forks), subgroups, and snippets within top-level groups to which they are explicitly granted access.
- Can access public groups and public projects.
- Can only access projects and groups to which they are explicitly granted access. External users cannot access internal or private projects or groups that they are not granted access to.
- Can only access public snippets.

Access can be granted by adding the user as member to the project or group.
Like usual users, they receive a role for the project or group with all
the abilities that are mentioned in the [permissions table](../user/permissions.md#project-members-permissions).
For example, if an external user is added as Guest, and your project is internal or
private, they do not have access to the code; you need to grant the external
user access at the Reporter level or above if you want them to have access to the code. You should
always take into account the
[project's visibility](../user/public_access.md#change-project-visibility) and [permissions settings](../user/project/settings/_index.md#configure-project-features-and-permissions)
as well as the permission level of the user.

{{< alert type="note" >}}

External users still count towards a license seat, unless the user has the [Guest role](../subscriptions/self_managed/_index.md#free-guest-users) in the Ultimate tier.

{{< /alert >}}

An administrator can flag a user as external by either of the following methods:

- [Through the API](../api/users.md#modify-a-user).
- Using the GitLab UI:
  1. On the left sidebar, at the bottom, select **Admin**.
  1. On the left sidebar, select **Overview > Users** to create a new user or edit an existing one.
     There, you can find the option to flag the user as external.

Additionally, users can be set as external users using:

- [SAML groups](../integration/saml.md#external-groups).
- [LDAP groups](auth/ldap/ldap_synchronization.md#external-groups).
- the [External providers list](../integration/omniauth.md#create-an-external-providers-list).

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

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand the **Account and limit** section.
1. Select the **Make new users external by default** checkbox.
1. Optional. In the **Email exclusion pattern** field, enter a regular expression.
1. Select **Save changes**.
