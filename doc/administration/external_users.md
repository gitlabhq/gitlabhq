---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: External users
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

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

NOTE:
External users still count towards a license seat, unless the user has the [Guest role](../subscriptions/self_managed/_index.md#free-guest-users) in the Ultimate tier.

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

## Set a new user to external

By default, new users are not set as external users. This behavior can be changed
by an administrator:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand the **Account and limit** section.

If you change the default behavior of creating new users as external, you
have the option to narrow it down by defining a set of internal users.
The **Internal users** field allows specifying an email address regex pattern to
identify default internal users. New users whose email address matches the regex
pattern are set to internal by default rather than an external collaborator.

The regex pattern format is in Ruby, but it needs to be convertible to JavaScript,
and the ignore case flag is set (`/regex pattern/i`). Here are some examples:

- Use `\.internal@domain\.com$` to mark email addresses ending with
  `.internal@domain.com` as internal.
- Use `^(?:(?!\.ext@domain\.com).)*$\r?` to mark users with email addresses
  not including `.ext@domain.com` as internal.

WARNING:
Be aware that this regex could lead to a
[regular expression denial of service (ReDoS) attack](https://en.wikipedia.org/wiki/ReDoS).
