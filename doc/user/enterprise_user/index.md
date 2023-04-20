---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference
---

# Enterprise users **(PREMIUM SAAS)**

Enterprise users have user accounts that are administered by an organization that
has purchased a [GitLab subscription](../../subscriptions/index.md).

Enterprise users are identified by the [**Enterprise** badge](../project/badges.md)
next to their names on the [Members list](../group/manage.md#filter-and-sort-members-in-a-group).

## Provision an enterprise user

A user account is considered an enterprise account when:

- A user without an existing GitLab user account uses the group's
  [SAML SSO](../group/saml_sso/index.md) to sign in for the first time.
- [SCIM](../group/saml_sso/scim_setup.md) creates the user account on behalf of
  the group.

A user can also [manually connect an identity provider (IdP) to a GitLab account whose email address matches the subscribing organization's domain](../group/saml_sso/index.md#link-saml-to-your-existing-gitlabcom-account).
By selecting **Authorize** when connecting these two accounts, the user account
with the matching email address is classified as an enterprise user. However, this
user account does not have an **Enterprise** badge in GitLab.

Although a user can be a member of more than one group, each user account can be
provisioned by only one group. As a result, a user is considered an enterprise
user under one top-level group only.

## Verified domains for groups

The following automated processes use [verified domains](../project/pages/custom_domains_ssl_tls_certification/index.md) to run:

- [Bypass email confirmation for provisioned users](#bypass-email-confirmation-for-provisioned-users).

### Set up a verified domain

Prerequisites:

- A project with [GitLab Pages](../project/pages/index.md), served under the default Pages domain `*.gitlab.io`.
- A custom domain name `example.com` or subdomain `subdomain.example.com`.
- Access to your domain's server control panel to set up a DNS `TXT` record to verify your domain's ownership.

Setting up a verified domain is similar to [setting up a custom domain on GitLab Pages](../project/pages/custom_domains_ssl_tls_certification/index.md). However, you must:

- Only configure the DNS `TXT` record to verify the domain's ownership.
- Ignore instructions for the `A`, `CNAME`, and `ALIAS` records.

1. [Add a custom domain](../project/pages/custom_domains_ssl_tls_certification/index.md#1-add-a-custom-domain) for the matching email domain.
   - The domain must match the email domain exactly. For example, if your email is `username@example.com`, verify the `example.com` domain.
1. [Get a verification code](../project/pages/custom_domains_ssl_tls_certification/index.md#2-get-the-verification-code).
1. [Set up the DNS `TXT`](../project/pages/custom_domains_ssl_tls_certification/index.md#3-set-up-dns-records) for your custom domain.
1. [Verify the domain's ownership](../project/pages/custom_domains_ssl_tls_certification/index.md#4-verify-the-domains-ownership).
1. Optional. [Add more domain aliases](../project/pages/custom_domains_ssl_tls_certification/index.md#add-more-domain-aliases).

### View domains in group

To view all configured domains in your group:

1. On the top bar, select **Main menu > Groups** and find your top-level group.
1. On the left sidebar, select **Settings > Domain Verification**.

You then see:

- A list of added domains.
- The domains' status of **Verified** or **Unverified**.
- The project where the domain has been configured.

## Manage enterprise users in a namespace

A top-level Owner of a namespace on a paid plan can retrieve information about and
manage enterprise user accounts in that namespace.

These enterprise user-specific actions are in addition to the standard
[group member permissions](../permissions.md#group-members-permissions).

### Disable two-factor authentication

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/9484) in GitLab 15.8.

Top-level group Owners can disable two-factor authentication (2FA) for enterprise users.

To disable 2FA:

1. On the top bar, select **Main menu > Groups** and find your group.
1. On the left sidebar, select **Group information > Members**.
1. Find a user with the **Enterprise** and **2FA** badges.
1. Select **More actions** (**{ellipsis_v}**) and select **Disable two-factor authentication**.

### Prevent users from creating groups and projects outside the corporate group

A SAML identity administrator can configure the SAML response to set:

- Whether users can create groups.
- The maximum number of personal projects users can create.

For more information, see the [supported user attributes for SAML responses](../group/saml_sso/index.md#supported-user-attributes).

### Bypass email confirmation for provisioned users

A top-level group Owner can [set up verified domains to bypass confirmation emails](../group/saml_sso/index.md#bypass-user-email-confirmation-with-verified-domains).

### Get users' email addresses through the API

A top-level group Owner can use the [group and project members API](../../api/members.md)
to access users' information, including email addresses.
