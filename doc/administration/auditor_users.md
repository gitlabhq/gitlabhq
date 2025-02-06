---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Auditor users

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

Users with auditor access have read-only access to all groups, projects, and other resources except:

- The [**Admin** area](admin_area.md).
- Project and group settings.

For more information, see [Auditor user permissions and restrictions](#auditor-user-permissions-and-restrictions)
section.

Situations where auditor access for users could be helpful include:

- Your compliance department wants to run tests against the entire GitLab base
  to ensure users are complying with password, credit card, and other sensitive
  data policies. You can achieve this with auditor access without giving the compliance department
  user administration rights or adding them to all projects.
- If particular users need visibility or access to most of all projects in
  your GitLab instance, instead of manually adding the user to all projects,
  you can create an account with auditor access and then share the credentials
  with those users to which you want to grant access.

NOTE:
An auditor user counts as a billable user and consumes a license seat.

## Add a user with auditor access

To create a new user account with auditor access (or change an existing user):

To create a user account with auditor access:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. Create a new user or edit an existing one. Set **Access Level** to **Auditor**.
1. If you created a user, select **Create user**. For an existing user, select **Save changes**.

To revoke auditor access from a user, follow these steps but set **Access Level** to **Regular**.

You can also give users auditor access using [SAML groups](../integration/saml.md#auditor-groups).

## Auditor user permissions and restrictions

Auditor access is _not_ a read-only version of administrator access because it doesn't permit access to the **Admin** area.

For access to their own resources and resources within a group or project where they are a member,
users with auditor access have the same [permissions](../user/permissions.md) as regular users.

If you are signed in with auditor access, you:

- Have full access to the projects and groups you own.
- Have read-only access to the projects and groups you are not a member of.
- Have [permissions](../user/permissions.md) based on your role to projects and groups you are a member of. For example, if you have the Developer role,
  you can push commits or comment on issues.
- Can access the same resources using the GitLab UI or API.
- Can't view the **Admin** area, or perform any administration actions.
- Can't view job logs when [debug logging](../ci/variables/_index.md#enable-debug-logging) is enabled.

## Maintain auditor users using API

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/366404) in GitLab 15.3.

Administrators can use the GitLab API to [create](../api/users.md#create-a-user) and
[modify](../api/users.md#modify-a-user) auditor users.
