---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Enterprise users
description: Domain verification, two-factor authentication, enterprise user management, and SAML response.
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

Enterprise users are administered by an organization that has [verified their email domain](#add-group-domains)
and purchased a [GitLab subscription](../../subscriptions/_index.md).

These users are identified by an `Enterprise` badge next to their names on the [Members list](../group/_index.md#filter-and-sort-members-in-a-group).

## Automatic claims of enterprise users

A user is automatically claimed as an enterprise user of a group when both of the following conditions are met:

- The user's primary email has a domain that has been [verified](#add-group-domains) by the group.
- The user account meets at least one of the following conditions:
  - It was created February 1, 2021 or later.
  - It has a SAML or SCIM identity tied to the organization's group.
  - It has a `provisioned_by_group_id` value that is the same as the group ID of the organization.
  - It is a member of the organization's group, where the subscription was purchased or renewed February 1, 2021 or later.

After the user is claimed as an enterprise user:

- Their `enterprise_group_id` attribute is set to the organization's group's ID.
- The user receives a [welcome email](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/views/notify/user_associated_with_enterprise_group_email.html.haml).

If a group's purchased subscription expires or is canceled:

- Users claimed as enterprise users remain enterprise users of that group.
- The group is not able to [manage their enterprise users](#manage-enterprise-users).
- Primary emails for user accounts must be from a verified domain.
- No new users can be [automatically associated with the group](#automatic-claims-of-enterprise-users) until the paid subscription is renewed.

If a group's verified domains are removed:

- Users claimed as enterprise users remain enterprise users of that group.
- Primary emails for user accounts must be from a verified domain.
- No new users can be [automatically associated with the group](#automatic-claims-of-enterprise-users) until domains are verified.

If the organization moves its verified domains to another paid group, its enterprise users are [automatically claimed](#automatic-claims-of-enterprise-users) as enterprise users of that group.

### Identifying unclaimed users

If a user is not automatically claimed as an enterprise user, their existing access will not be revoked.
A group with domain verification enabled can have both claimed and unclaimed users as members.

The only difference between a member claimed as an enterprise user and a member that is not is that a Group Owner cannot [manage unclaimed users](#manage-enterprise-users).

### Identifying group members that have not been claimed as enterprise users

Groups that enable domain verification can have both claimed and unclaimed users as members.
Unclaimed users retain their existing access, but are not managed by group Owners.

See [Manage enterprise users in a namespace](#manage-enterprise-users).

You can discover any unclaimed users in your group by accessing and analyzing your list of billable
users at: `https://gitlab.com/groups/<group_id>/-/usage_quotas#seats-quota-tab`.

From this list, unclaimed users one of the following:

- No visible email address.
- An email address that does not match your verified domain.

To claim these users, they must update their primary email address to match the verified domain.
These users are automatically claimed when the next scheduled claim worker runs.

## Manage group domains

To claim GitLab.com users as enterprise users, you must add and verify ownership of a domain.
Group domains are added to the top-level group and apply to all subgroups and projects
in the group. While each group can have multiple domains, you can associate each domain
with only one group at a time.

Group domains are linked to a project in your top-level group. The
linked project needs [GitLab Pages](../project/pages/_index.md), but does
not need to create a GitLab Pages website. If GitLab Pages is turned off, you cannot
verify the domain.

Group domains are linked to a specified project in the top-level group, but apply to the
entire group hierarchy including all nested subgroups and projects. Members in the linked project with
[at least the Maintainer role](../permissions.md#project-members-permissions) can modify or
remove the domain. If this project is deleted, your associated domains are also removed.

For more information on group domains, see [epic 5299](https://gitlab.com/groups/gitlab-org/-/epics/5299).

### Add group domains

Prerequisites:

- You must have the Owner role for a top-level group.
- You must control a custom domain `example.com` or subdomain `subdomain.example.com` that matches the email domain you want to verify.
- You must be able to create DNS `TXT` records for your domain to prove ownership.
- You must have a dedicated project in the top-level group that uses
  [GitLab Pages](../project/pages/_index.md).

To add a custom domain for a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Domain Verification**.
1. In the upper-right corner, select **Add Domain**.
1. Configure the domain settings:
   - **Domain**: Enter the domain name.
   - **Project**: Link to an existing project in the group.
   - **Certificate**: Select a certificate option:
     - If you do not have or do not want to use an SSL/TLS certificate, select
       **Automatic certificate management using Let's Encrypt**.
     - If you want to provide your own SSL/TLS certificate, select
       **Manually enter certificate information**. You can also add a certificate and key later.

        {{< alert type="note" >}}

        A valid certificate is not required for domain verification. You can ignore self-signed certificate warnings
        if you are not using GitLab Pages.

        {{< /alert >}}

1. Select **Add Domain**.
   GitLab saves the domain information.
1. Verify ownership of the domain:
   1. In **TXT**, copy the verification code.
   1. In your domain provider DNS settings, add the verification code as a `TXT` record.
   1. In GitLab, on the left sidebar, select **Search or go to** and find your group.
   1. Select **Settings > Domain Verification**.
   1. Next to the domain name, select **Retry verification** ({{< icon name="retry" >}}).

After successful verification, the domain status changes to **Verified** and can be used for enterprise user management.

   {{< alert type="note" >}}

   Generally, DNS propagation completes in a few minutes, but can take up to 24 hours.
   Until it completes, the domain remains unverified in GitLab.

   If the domain is still unverified after seven days, GitLab automatically removes the domain.

   After verification, GitLab periodically reverifies the domain. To avoid potential issues,
   maintain the `TXT` record on your domain provider.

   {{< /alert >}}

### View group domains

To view all custom domains for a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Domain Verification**.

### Edit group domains

To edit a custom domain for a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Domain Verification**.
1. Next to the domain name, select **Edit** ({{< icon name="pencil" >}}).

From here, you can:

- View the custom domain.
- View the DNS record to add.
- View the TXT verification entry.
- Retry verification.
- Edit the certificate settings.

### Delete group domains

To delete a custom domain for a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Domain Verification**.
1. Next to the domain name, select **Remove domain** ({{< icon name="remove" >}}).
1. When prompted, select **Delete domain**.

## Manage enterprise users

In addition to the standard [group member permissions](../permissions.md#group-members-permissions),
Owners of a top-level group can also manage enterprise users in their group.

You can also [use the API](../../api/group_enterprise_users.md) to interact with enterprise users.

### Restrict authentication methods

You can restrict the specific authentication methods available to enterprise users, which can help
reduce the security footprint of your users.

- [Disable password authentication](../group/saml_sso/_index.md#disable-password-authentication-for-enterprise-users).
- [Disable personal access tokens](../../user/profile/personal_access_tokens.md#disable-personal-access-tokens-for-enterprise-users).
- [Disable two-factor authentication](../../security/two_factor_authentication.md#enterprise-users).

### Restrict group and project creation

You can restrict group and project creation for enterprise users, which helps you define:

- If enterprise users can create top-level groups.
- The maximum number of personal projects each enterprise user can create.

These restrictions are defined in the SAML response. For more information, see
[configure enterprise user settings from the SAML response](../group/saml_sso/_index.md#configure-enterprise-user-settings-from-saml-response).

### Bypass email confirmation for provisioned users

By default, users provisioned with SAML or SCIM are sent a verification email to verify their
identity. Instead, you can configure GitLab with a custom domain and GitLab automatically
confirms user accounts. Users still receive an enterprise user welcome email.

For more information, see [bypass user email confirmation with verified domains](../group/saml_sso/_index.md#bypass-user-email-confirmation-with-verified-domains).

### View the email addresses for an enterprise user

Prerequisites:

- You must have the Owner role for a top-level group.

To view an enterprise user's email address:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Manage > Members**.
1. Hover over the enterprise user's name.

You can also use the [group and project members API](../../api/members.md)
to access users' information. For enterprise users of the group, this information
includes users' email addresses.

### Change the email addresses for an enterprise user

Enterprise users can follow the same process as other GitLab users to
[change their primary email address](../../user/profile/_index.md#change-your-primary-email).
The new email address must be from a verified domain. If your organization has no verified
domains, your enterprise users cannot change their primary email address.

Only GitLab support can change the primary email address to an email address from a
non-verified domain. This action [releases the enterprise user](#release-an-enterprise-user).

### Delete an enterprise user

Prerequisites:

- You must have the Owner role for the top-level group.

You can use the [group enterprise users API](../../api/group_enterprise_users.md#delete-an-enterprise-user)
to delete an enterprise user and permanently remove the account from GitLab. This action is different from
releasing the user which only removes the enterprise management features from the user. When you delete
the user, you can choose to either:

- Permanently delete the user and their
  [contributions](../../user/profile/account/delete_account.md#associated-records).
- Keep their contributions and transfer them to a system-wide ghost user account.

### Release an enterprise user

You can remove enterprise management features from a user account. Removing an enterprise user might be required if, for
example, a user wants to keep their GitLab account after leaving their company. Releasing a user
does not alter their account roles or permissions, but removes the management options
for the group Owner. If you need to permanently remove the account, you should
[delete the user](#delete-an-enterprise-user) instead.

To release the user, GitLab support must update the user's primary email address to an
email address from a non-verified domain. This action automatically releases the account.

Allowing group Owners to change primary emails is proposed in
[issue 412966](https://gitlab.com/gitlab-org/gitlab/-/issues/412966).

### Enable the extension marketplace for the Web IDE and workspaces

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161819) as a [beta](../../policy/development_stages_support.md#beta) in GitLab 17.4 [with flags](../../administration/feature_flags/_index.md) named `web_ide_oauth` and `web_ide_extensions_marketplace`. Disabled by default.
- `web_ide_oauth` [enabled on GitLab.com, GitLab Self-Managed, and GitLab Dedicated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/163181) in GitLab 17.4.
- `web_ide_extensions_marketplace` [enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/459028) in GitLab 17.4.
- `web_ide_oauth` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/167464) in GitLab 17.5.
- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/508996) the `vscode_extension_marketplace_settings` [feature flag](../../administration/feature_flags/_index.md) in GitLab 17.10. Disabled by default.
- `web_ide_extensions_marketplace` [enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184662), and `vscode_extension_marketplace_settings` [enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184662) in GitLab 17.11.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/192659) in GitLab 18.1. Feature flags `web_ide_extensions_marketplace` and `vscode_extension_marketplace_settings` removed.

{{< /history >}}

Prerequisites:

- An administrator must [enable the extension marketplace](../../administration/settings/vscode_extension_marketplace.md).
- You must have the Owner role for a top-level group.

To enable the extension marketplace for the [Web IDE](../project/web_ide/_index.md) and [workspaces](../workspace/_index.md):

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > General**.
1. Expand **Permissions and group features**.
1. Under **Web IDE and workspaces**, select the **Enable extension marketplace** checkbox.
1. Select **Save changes**.

## Troubleshooting

### Cannot disable two-factor authentication for an enterprise user

If a user does not have an **Enterprise** badge, a group Owner cannot disable or reset 2FA for their
account. Instead, the Owner should tell the enterprise user to consider available
[recovery options](../profile/account/two_factor_authentication_troubleshooting.md#recovery-options-and-2fa-reset).

## Related topics

- [GitLab Pages custom domains](../project/pages/custom_domains_ssl_tls_certification/_index.md).
