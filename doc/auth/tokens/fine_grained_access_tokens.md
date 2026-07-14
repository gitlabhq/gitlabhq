---
stage: Software Supply Chain Security
group: Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Fine-grained personal access tokens
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/18555) as a [beta](../../policy/development_stages_support.md#beta) in GitLab 18.10.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/596613) in GitLab 19.2.

{{< /history >}}

Fine-grained personal access tokens are scoped to only access the specific resources and permissions
you define. When creating the token, you define the following attributes:

- Resources: A collection of API operations. Resources are grouped into larger boundaries (
  `Group and project`, `User`, and `Global`).
- Permissions: The specific actions the token can perform on a resource. Generally, this conforms to
  Create, Read, Update, and Delete actions.

## Create a fine-grained personal access token

To create a fine-grained personal access token:

1. In the upper-right corner, select your avatar.
1. Select **Edit profile**.
1. In the left sidebar, select **Access** > **Personal access tokens**.
1. From the **Generate token** dropdown list, select **Fine-grained token**.
1. Complete the **Name** and **Description** fields.
1. In the **Expiration date** text box, enter an expiry date for the token.
   - The token expires at midnight UTC on that date.
   - If you do not enter a date, the expiry date is set to 365 days from today.
   - By default, the expiry date cannot be more than 365 days from today. On GitLab 17.6 and later,
     administrators can [modify the maximum lifetime of access tokens](../../administration/settings/account_and_limit_settings.md#limit-the-lifetime-of-access-tokens).
1. If you're adding group or project resources, under **Group and project access**, select an option.
1. Under **Add resource permissions**:
   1. Use the **Group and project**, **User**, or **Global** tabs to filter resources by boundary.
   1. In the left panel, select one or more resources.
   1. In the right panel, select an [available permission](#available-fine-grained-permissions) for each resource.
1. Select **Generate token**.

A personal access token is displayed. Save the personal access token somewhere safe. After you leave
or refresh the page, you cannot view it again.

## Impersonate users with sudo

Administrators can create a fine-grained personal access token that can impersonate other users
with the [`sudo`](../../api/rest/authentication.md#sudo) parameter on the REST API.

Only an administrator can create a token with the sudo capability. A non-administrator that tries
to create one receives an error.

A fine-grained token continues to enforce its own permissions while impersonating. The token can
perform an action only when both of the following are true:

- The impersonated user is allowed to perform the action.
- The token has a permission that allows the action.

This behavior differs from a legacy personal access token with the `sudo` scope, which can perform
any action as the impersonated user.

> [!warning]
> A token with the sudo capability can act as any user. Restrict its permissions and boundaries to
> the minimum required, and store it securely.

## Available fine-grained permissions

The permissions a fine-grained personal access token can use depend on the endpoint the token
calls:

- [Fine-grained permissions for REST API](fine_grained_access_tokens_rest.md)
- [Fine-grained permissions for GraphQL API](fine_grained_access_tokens_graphql.md)
- [Fine-grained permissions for Git and other operations](fine_grained_access_tokens_other.md)

## Enforce fine-grained personal access tokens

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/20180) in GitLab 18.11 [with flags](../../administration/feature_flags/_index.md) named `granular_personal_access_tokens_enforcement` and `granular_personal_access_tokens_enforcement_saas`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/596613) on GitLab Self-Managed in GitLab 19.2.

{{< /history >}}

You can require your users to adopt fine-grained personal access tokens after a specified enforcement
date. After this date, any existing legacy personal access tokens remain listed in user profiles, but
cannot be used to access resources.

Enforcement works differently on GitLab.com and GitLab Self-Managed:

- On GitLab.com, enforcement is applied to a top-level group and inherited by all subgroups and projects.
- On GitLab Self-Managed, enforcement is applied to the entire instance.

### Enforce fine-grained tokens for a top-level group

Prerequisites:

- You must have the Owner role for the top-level group.

On GitLab.com, enforcement applies to the group and its subgroups and projects, and blocks legacy
personal access tokens from accessing those resources after the enforcement date. Users can still
create legacy tokens, but those tokens cannot access the enforced resources for the group.

This setting is not available on GitLab Self-Managed.

You can enforce fine-grained tokens only on a top-level group.

To enforce fine-grained personal access tokens for a top-level group:

1. In the left sidebar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. Expand **Permissions and group features**.
1. Select **Require fine-grained personal access tokens after a specific date**.
1. Enter a future enforcement date.
   The enforcement date is in Coordinated Universal Time (UTC).
1. Select **Save changes**.

After the enforcement date, users receive an error when they attempt to use a legacy token to access
resources in the top-level group, any subgroups, or projects. The error lists the resource boundary
and permissions a fine-grained token needs. For example:

```plaintext
Access denied: This operation requires a fine-grained personal access token with the following project permissions: [Project: Read].
```

### Enforce fine-grained tokens on GitLab Self-Managed

Prerequisites:

- You must be an administrator.

On GitLab Self-Managed, enforcement applies to the entire instance, and blocks users from creating or
rotating legacy personal access tokens after the enforcement date. Users can create fine-grained
tokens only. Existing legacy tokens continue to work until they expire.

To enforce fine-grained personal access tokens for the instance:

1. In the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Account and limit**.
1. Select **Require fine-grained personal access tokens after a specific date**.
1. In **Fine-grained personal access tokens enforcement date**, enter a future date.
1. Select **Save changes**.

After the enforcement date, users receive an error when they attempt to create or rotate a legacy token.
