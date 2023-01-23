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

A user can also [manually connect an identity provider (IdP) to a GitLab account whose email address matches the subscribing organization's domain](../group/saml_sso/index.md#linking-saml-to-your-existing-gitlabcom-account).
By selecting **Authorize** when connecting these two accounts, the user account
with the matching email address is classified as an enterprise user. However, this
user account does not have an **Enterprise** badge in GitLab.

Although a user can be a member of more than one group, each user account can be
provisioned by only one group. As a result, a user is considered an enterprise
user under one top-level group only.

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

A SAML IdP administrator or a top-level group Owner can use a SAML response to set:

- Whether users can create groups.
- The maximum number of personal projects users can create.

For more information, see the [supported user attributes for SAML responses](../group/saml_sso/index.md#supported-user-attributes).

### Bypass email confirmation for provisioned users

A top-level group Owner can [set up verified domains to bypass confirmation emails](../group/saml_sso/index.md#bypass-user-email-confirmation-with-verified-domains).

### Get users' email addresses through the API

A top-level group Owner can use the [group and project members API](../../api/members.md)
to access users' information, including email addresses.
