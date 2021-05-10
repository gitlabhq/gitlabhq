---
type: reference, howto
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Group Managed Accounts **(PREMIUM)**

WARNING:
This [Closed Beta](https://about.gitlab.com/handbook/product/gitlab-the-product/#sts=Closed%20Beta) feature is being re-evaluated in favor of a different
[approach](https://gitlab.com/groups/gitlab-org/-/epics/4786) that aligns more closely with our [Subscription Agreement](https://about.gitlab.com/handbook/legal/subscription-agreement/).
We recommend that group owners who haven't yet implemented this feature wait for the new solution.

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/709) in GitLab 12.1.
> - It's deployed behind a feature flag, disabled by default.

When [SSO for Groups](index.md) is enforced, groups can enable an additional level of protection by enforcing the creation of dedicated user accounts to access the group.

With group-managed accounts enabled, users are required to create a new, dedicated user linked to the group.
The notification email address associated with the user is locked to the email address received from the configured identity provider.
Without group-managed accounts, users can link their SAML identity with any existing user on the instance.

When this option is enabled:

- All users in the group are required to log in via the SSO URL associated with the group.
- After the group-managed account has been created, group activity requires the use of this user account.
- Users can't share a project in the group outside the top-level group (also applies to forked projects).

Upon successful authentication, GitLab prompts the user with options, based on the email address received from the configured identity provider:

- To create a unique account with the newly received email address.
- If the received email address matches one of the user's verified GitLab email addresses, the option to convert the existing account to a group-managed account. ([Introduced in GitLab 12.9](https://gitlab.com/gitlab-org/gitlab/-/issues/13481).)

Since use of the group-managed account requires the use of SSO, users of group-managed accounts lose access to these accounts when they are no longer able to authenticate with the connected identity provider. In the case of an offboarded employee who has been removed from your identity provider:

- The user is unable to access the group (their credentials no longer work on the identity provider when prompted to use SSO).
- Contributions in the group (for example, issues and merge requests) remains intact.

Please refer to our [SAML SSO for Groups page](../index.md) for information on how to configure SAML.

## Feature flag **(PREMIUM SELF)**

The group-managed accounts feature is behind these feature flags: `group_managed_accounts`, `sign_up_on_sso` and `convert_user_to_group_managed_accounts`. The flags are disabled by default.
To activate the feature, ask a GitLab administrator with Rails console access to run:

```ruby
Feature.enable(:group_managed_accounts)
Feature.enable(:sign_up_on_sso)
Feature.enable(:convert_user_to_group_managed_accounts)
```

## Project restrictions for Group-managed accounts

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/12420) in GitLab 12.9.

Projects within groups with enabled group-managed accounts are not to be shared with:

- Groups outside of the parent group.
- Members who are not users managed by this group.

This restriction also applies to projects forked from or to those groups.

## Outer forks restriction for Group-managed accounts

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/34648) in GitLab 12.9.

Groups with group-managed accounts can disallow forking of projects to destinations outside the group.
To do so, enable the "Prohibit outer forks" option in **Settings > SAML SSO**.
When enabled **at the parent group level**, projects within the group can be forked
only to other destinations within the group (including its subgroups).

## Credentials inventory for Group-managed accounts **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/38133) in GitLab 12.8.

Owners who manage user accounts in a group can view the following details of personal access tokens and SSH keys:

- Owners
- Scopes
- Usage patterns

To access the Credentials inventory of a group, navigate to **{shield}** **Security & Compliance > Credentials** in your group's sidebar.

This feature is similar to the [Credentials inventory for self-managed instances](../../admin_area/credentials_inventory.md).

### Revoke a group-managed account's personal access token

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/214811) in GitLab 13.5.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/267184) in GitLab 13.10.

Group owners can revoke the personal access tokens of accounts in their group. To do so, select
the Personal Access Tokens tab, and select Revoke.

When a personal access token is revoked, the group-managed account user is notified by email.

## Limiting lifetime of personal access tokens of users in Group-managed accounts **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/118893) in GitLab 12.10.

Users in a group managed account can optionally specify an expiration date for
[personal access tokens](../../profile/personal_access_tokens.md).
This expiration date is not a requirement, and can be set to any arbitrary date.

Since personal access tokens are the only token needed for programmatic access to GitLab, organizations with security requirements may want to enforce more protection to require regular rotation of these tokens.

### Set a limit

Only a GitLab administrator or an owner of a group-managed account can set a limit. When this field
is left empty, the [instance-level restriction](../../admin_area/settings/account_and_limit_settings.md#limit-the-lifetime-of-personal-access-tokens)
on the lifetime of personal access tokens apply.

To set a limit on how long personal access tokens are valid for users in a group managed account:

1. Navigate to the **Settings > General** page in your group's sidebar.
1. Expand the **Permissions, LFS, 2FA** section.
1. Fill in the **Maximum allowable lifetime for personal access tokens (days)** field.
1. Click **Save changes**.

Once a lifetime for personal access tokens is set:

- GitLab applies the lifetime for new personal access tokens and requires users managed by the group to set an expiration date that's no later than the allowed lifetime.
- After three hours, revoke old tokens with no expiration date or with a lifetime longer than the allowed lifetime. Three hours is given to allow administrators/group owner to change the allowed lifetime, or remove it, before revocation takes place.
