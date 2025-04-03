---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: SAML Group Sync
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/363084) to GitLab Self-Managed in GitLab 15.1.

{{< /history >}}

Use SAML group sync to assign users with specific roles to existing GitLab groups,
based on the users' group assignment in the SAML identity provider (IdP).
With SAML group sync you can create a many-to-many mapping between SAML IdP groups and GitLab groups.

For example, if the user `@amelia` is assigned to the `security` group in the SAML IdP,
you can use SAML group sync to assign `@amelia` to the `security-gitlab` group with Maintainer role,
and to the `vulnerability` group with Reporter role.

SAML group sync does not create groups.
You have to first [create a group](../_index.md#create-a-group), then create the mapping.

On GitLab.com, SAML group sync is configured by default.
On GitLab Self-Managed, you must configure it manually.

## Role prioritization

Group sync determines the role and membership type of a user in the mapped group.

### Multiple SAML IdPs

{{< details >}}

- Offering: GitLab Self-Managed

{{< /details >}}

When a user signs in, GitLab:

- Checks all the configured SAML group links.
- Adds that user to the corresponding GitLab groups based on the SAML groups the user belongs to across the different IdPs.

The group link mapping in GitLab is not tied to a specific IdP so you must configure all SAML IdPs to contain group attributes in the SAML response. This means that GitLab is able to match groups in the SAML response, regardless of the IdP that was used to sign in.

As an example, you have 2 IdPs: `SAML1` and `SAML2`.

In GitLab, on a specific group, you have configured two group links:

- `gtlb-owner => Owner role`.
- `gtlb-dev => Developer role`.

In `SAML1`, the user is a member of `gtlb-owner` but not `gtlb-dev`.

In `SAML2`, the user is a member of `gtlb-dev` but not `gtlb-owner`.

When a user signs in to a group with `SAML1`, the SAML response shows that the user is a member of `gtlb-owner`, so GitLab sets the user's role in that group to be `Owner`.

The user then signs out and signs back in to the group with `SAML2`. The SAML response shows that the user is a member of `gtlb-dev`, so GitLab sets the user's role in that group to be `Developer`.

Now let's change the previous example so that the user is not a member of either `gtlb-owner` or `gtlb-dev` in `SAML2`.

- When the user signs in to a group with `SAML1`, the user is given the `Owner` role in that group.
- When the user signs in with `SAML2`, the user is removed from the group because they are not a member of either configured group link.

### Multiple SAML groups

If a user is a member of multiple SAML groups that map to the same GitLab group, the user is assigned the highest role from any of those SAML groups.

For example, if a user has the Guest role in a group and the Maintainer role in another group, they are assigned the Maintainer role.

### Membership types

If a user's role in a SAML group is higher than their role in one of its subgroups, their [membership](../../project/members/_index.md#display-direct-members) in the mapped GitLab group is different based on their assigned role in the mapped group.

If through group sync the user was assigned:

- A higher role, they are a direct member of the group.
- A role that is the same as or lower, they are an inherited member of the group.

## Automatic member removal

After a group sync, users who are not members of a mapped SAML group are removed from the group.
On GitLab.com, users in the top-level group are assigned the
default membership role instead of being removed.

For example, in the following diagram:

- Alex Garcia signs into GitLab and is removed from GitLab Group C because they don't belong
  to SAML Group C.
- Sidney Jones belongs to SAML Group C, but is not added to GitLab Group C because they have
  not yet signed in.

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
graph TB
accTitle: Automatic member removal
accDescr: How group membership of users is determined before sign in if group sync is set up.

   subgraph SAML users
      SAMLUserA[Sidney Jones]
      SAMLUserB[Zhang Wei]
      SAMLUserC[Alex Garcia]
      SAMLUserD[Charlie Smith]
   end

   subgraph SAML groups
      SAMLGroupA["Group A"] --> SAMLGroupB["Group B"]
      SAMLGroupA --> SAMLGroupC["Group C"]
      SAMLGroupA --> SAMLGroupD["Group D"]
   end

   SAMLGroupB --> |Member|SAMLUserA
   SAMLGroupB --> |Member|SAMLUserB

   SAMLGroupC --> |Member|SAMLUserA
   SAMLGroupC --> |Member|SAMLUserB

   SAMLGroupD --> |Member|SAMLUserD
   SAMLGroupD --> |Member|SAMLUserC
```

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
graph TB
accTitle: Automatic member removal
accDescr: User membership for Sidney when she has not signed into group C, and group B has not configured group links.

    subgraph GitLab users
      GitLabUserA[Sidney Jones]
      GitLabUserB[Zhang Wei]
      GitLabUserC[Alex Garcia]
      GitLabUserD[Charlie Smith]
    end

   subgraph GitLab groups
      GitLabGroupA["Group A<br> (SAML configured)"] --> GitLabGroupB["Group B<br> (SAML Group Link not configured)"]
      GitLabGroupA --> GitLabGroupC["Group C<br> (SAML Group Link configured)"]
      GitLabGroupA --> GitLabGroupD["Group D<br> (SAML Group Link configured)"]
   end

   GitLabGroupB --> |Member|GitLabUserA

   GitLabGroupC --> |Member|GitLabUserB
   GitLabGroupC --> |Member|GitLabUserC

   GitLabGroupD --> |Member|GitLabUserC
   GitLabGroupD --> |Member|GitLabUserD
```

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
graph TB
accTitle: Automatic member removal
accDescr: How membership of Alex Garcia works once she has signed into a group that has group links enabled.

   subgraph GitLab users
      GitLabUserA[Sidney Jones]
      GitLabUserB[Zhang Wei]
      GitLabUserC[Alex Garcia]
      GitLabUserD[Charlie Smith]
   end

   subgraph GitLab groups after Alex Garcia signs in
      GitLabGroupA[Group A]
      GitLabGroupA["Group A<br> (SAML configured)"] --> GitLabGroupB["Group B<br> (SAML Group Link not configured)"]
      GitLabGroupA --> GitLabGroupC["Group C<br> (SAML Group Link configured)"]
      GitLabGroupA --> GitLabGroupD["Group D<br> (SAML Group Link configured)"]
   end

   GitLabGroupB --> |Member|GitLabUserA
   GitLabGroupC --> |Member|GitLabUserB
   GitLabGroupD --> |Member|GitLabUserC
   GitLabGroupD --> |Member|GitLabUserD
```

## Configure SAML Group Sync

Adding or changing a group sync configuration may remove users from the mapped GitLab group,
if the group names don't match the listed `groups` in the SAML response.
To avoid users being removed, before configuring group sync, ensure either:

- The SAML response includes the `groups` attribute and the `AttributeValue` value matches the **SAML Group Name** in GitLab.
- All groups are removed from GitLab to disable Group Sync.

If you use SAML Group Sync and have multiple GitLab nodes, for example in a distributed or highly available architecture,
you must include the SAML configuration block on all Sidekiq nodes in addition to Rails application nodes.

{{< tabs >}}

{{< tab title="GitLab.com" >}}

To configure SAML Group Sync:

1. See [SAML SSO for GitLab.com groups](_index.md).
1. Ensure your SAML identity provider sends an attribute statement named `Groups` or `groups`.

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

To configure SAML Group Sync:

1. Configure the [SAML OmniAuth Provider](../../../integration/saml.md).
1. Ensure your SAML identity provider sends an attribute statement with the same name as the value of the `groups_attribute` setting. This attribute is case-sensitive. See the following provider configuration example in `/etc/gitlab/gitlab.rb` for reference:

   ```ruby
   gitlab_rails['omniauth_providers'] = [
     {
       name: "saml",
       label: "Provider name", # optional label for login button, defaults to "Saml",
       groups_attribute: 'Groups',
       args: {
         assertion_consumer_service_url: "https://gitlab.example.com/users/auth/saml/callback",
         idp_cert_fingerprint: "43:51:43:a1:b5:fc:8b:b7:0a:3a:a9:b1:0f:66:73:a8",
         idp_sso_target_url: "https://login.example.com/idp",
         issuer: "https://gitlab.example.com",
         name_identifier_format: "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
       }
     }
   ]
   ```

{{< /tab >}}

{{< /tabs >}}

The value for `Groups` or `groups` in the SAML response may be either the group name or an ID.
For example, Azure AD sends the Azure Group Object ID instead of the name. Use the ID value when configuring [SAML Group Links](#configure-saml-group-links).

```xml
<saml:AttributeStatement>
  <saml:Attribute Name="Groups">
    <saml:AttributeValue xsi:type="xs:string">Developers</saml:AttributeValue>
    <saml:AttributeValue xsi:type="xs:string">Product Managers</saml:AttributeValue>
  </saml:Attribute>
</saml:AttributeStatement>
```

Other attribute names such as `http://schemas.microsoft.com/ws/2008/06/identity/claims/groups`
are not accepted as a source of groups.

For more information on configuring the
required group attribute name in the SAML identity provider's settings, see
example configurations for [Azure AD](example_saml_config.md#group-sync) and [Okta](example_saml_config.md#group-sync-1).

## Configure SAML group links

SAML Group Sync only manages a group if that group has one or more SAML group links.

Prerequisites:

- Your GitLab Self-Managed instance must have configured SAML Group Sync.

When SAML is enabled, users with the Owner role see a new menu
item in group **Settings > SAML Group Links**.

- You can configure one or more **SAML Group Links** to map a SAML IdP group name to a GitLab role.
- Members of the SAML IdP group are added as members of the GitLab
  group on their next SAML sign-in.
- Group membership is evaluated each time a user signs in using SAML.
- SAML Group Links can be configured for a top-level group or any subgroup.
- If a SAML group link is created then removed, and there are:
  - Other SAML group links configured, users that were in the removed group
    link are automatically removed from the group during sync.
  - No other SAML group links configured, users remain in the group during sync.
    Those users must be manually removed from the group.

To link the SAML groups:

1. In **SAML Group Name**, enter the value of the relevant `saml:AttributeValue`. The value entered here must exactly match the value sent in the SAML response. For some IdPs, this may be a group ID or object ID (Azure AD) instead of a friendly group name.
1. Choose a [default role](../../permissions.md) or [custom role](../../custom_roles/_index.md) in **Access Level**.
1. Select **Save**.
1. Repeat to add additional group links if required.

![SAML Group Links](img/saml_group_links_v17_8.png)

## Manage GitLab Duo seat assignment

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/480766) for GitLab.com in GitLab 17.8 [with a flag](../../../administration/feature_flags.md) named `saml_groups_duo_pro_add_on_assignment`. Disabled by default.

{{< /history >}}

Prerequisites:

- An active [GitLab Duo add-on subscription](../../../subscriptions/subscription-add-ons.md)

SAML Group Sync can manage GitLab Duo seat assignment and removal based on IdP group membership. Seats are only assigned when there are seats remaining in the subscription.

1. When [configuring a SAML Group Link](#configure-saml-group-links), select the **Assign GitLab Duo seats to users in this group** checkbox.
1. Select **Save**.
1. Repeat to add additional group links for all SAML users that should be assigned a GitLab Duo Pro or GitLab Duo Enterprise seat.
   GitLab Duo seats are unassigned for users whose identity provider group memberships do not match a group link with this setting enabled.

The checkbox does not appear for groups without an active GitLab Duo add-on subscription.

## Microsoft Azure Active Directory integration

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10507) in GitLab 16.3.

{{< /history >}}

{{< alert type="note" >}}

Microsoft has [announced](https://azure.microsoft.com/en-us/updates/azure-ad-is-becoming-microsoft-entra-id/) that Azure Active Directory (AD) is being renamed to Entra ID.

{{< /alert >}}

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For a demo of group sync using Microsoft Azure, see [Demo: SAML Group Sync](https://youtu.be/Iqvo2tJfXjg).

Azure AD sends up to 150 groups in the `groups` claim.
When using Azure AD with SAML Group Sync, if a user in your organization is a member of more than 150 groups,
Azure AD sends a `groups` claim attribute in the SAML response for [group overages](https://learn.microsoft.com/en-us/security/zero-trust/develop/configure-tokens-group-claims-app-roles#group-overages),
and the user may be automatically removed from groups.

To avoid this issue, you can use the Azure AD integration, which:

- Is not limited to 150 groups.
- Uses the Microsoft Graph API to obtain all user memberships.
  The [Graph API endpoint](https://learn.microsoft.com/en-us/graph/api/user-list-transitivememberof?view=graph-rest-1.0&tabs=http#http-request) accepts only a
  [user object ID](https://learn.microsoft.com/en-us/partner-center/find-ids-and-domain-names#find-the-user-object-id) or
  [userPrincipalName](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/plan-connect-userprincipalname#what-is-userprincipalname)
  as the [Azure-configured](_index.md#azure) Unique User Identifier (Name identifier) attribute.
- Supports only Group Links configured with group unique identifiers (like `12345678-9abc-def0-1234-56789abcde`)
  when it processes Group Sync.

Alternatively, you can change the [group claims](https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-fed-group-claims#configure-the-microsoft-entra-application-registration-for-group-attributes) to use the **Groups assigned to the application** option.

![Manage Group Claims](img/Azure-manage-group-claims_v15_9.png)

### Configure Azure AD

As part of the integration, you must allow GitLab to communicate with the Microsoft Graph API.

<!-- vale gitlab_base.SentenceSpacing = NO -->

To configure Azure AD:

1. In the [Azure Portal](https://portal.azure.com), go to **Microsoft Entra ID > App registrations > All applications**, and select your GitLab SAML application.
1. Under **Essentials**, the **Application (client) ID** and **Directory (tenant) ID** values are displayed. Copy these values, because you need them for the GitLab configuration.
1. In the left navigation, select **Certificates & secrets**.
1. On the **Client secrets** tab, select **New client secret**.
   1. In the **Description** text box, add a description.
   1. In the **Expires** dropdown list, set the expiration date for the credentials. If the secret expires, the GitLab integration will no longer work until the credentials are updated.
   1. To generate the credentials, select **Add**.
   1. Copy the **Value** of the credential. This value is displayed only once, and you need it for the GitLab configuration.
1. In the left navigation, select **API permissions**.
1. Select **Microsoft Graph > Application permissions**.
1. Select the checkboxes **GroupMember.Read.All** and **User.Read.All**.
1. Select **Add permissions** to save.
1. Select **Grant admin consent for `<application_name>`**, then on the confirmation dialog select **Yes**. The **Status** column for both permissions should change to a green check with **Granted for `<application_name>`**.

<!-- vale gitlab_base.SentenceSpacing = YES -->

### Configure GitLab

After you configure Azure AD, you must configure GitLab to communicate with Azure AD.

With this configuration, if a user signs in with SAML and Azure sends a `group` claim in the response,
GitLab initiates a Group Sync job to call the Microsoft Graph API and retrieve the user's group membership.
Then the GitLab group membership is updated according to SAML Group Links.

The following table lists the GitLab settings and the corresponding Azure AD fields for the configuration:

| GitLab setting | Azure field                                |
| -------------- | ------------------------------------------ |
| Tenant ID      | Directory (tenant) ID                      |
| Client ID      | Application (client) ID                    |
| Client Secret  | Value (on **Certificates & secrets** page) |

{{< tabs >}}

{{< tab title="GitLab.com" >}}

To configure Azure AD for a GitLab.com group:

1. On the left sidebar, select **Search or go to** and find your group.
   This group must be at the top level.
1. Select **Settings > SAML SSO**.
1. Configure [SAML SSO for the group](_index.md).
1. In the **Microsoft Azure integration** section, select the **Enable Microsoft Azure integration for this group** checkbox.
   This section is only visible if SAML SSO is configured and enabled for the group.
1. Enter the **Tenant ID**, **Client ID**, and **Client secret** obtained earlier when configuring Azure Active Directory in the Azure Portal.
1. Optional. If using Azure AD for US Government or Azure AD China, enter the appropriate **Login API endpoint** and **Graph API endpoint**. The default values work for most organizations.
1. Select **Save changes**.

{{< /tab >}}

{{< tab title="GitLab Self-Managed" >}}

To configure for GitLab Self-Managed:

1. Configure [SAML SSO for the instance](../../../integration/saml.md).
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. In the **Microsoft Azure integration** section, select the **Enable Microsoft Azure integration for this group** checkbox.
1. Enter the **Tenant ID**, **Client ID**, and **Client secret** obtained earlier when configuring Azure Active Directory in the Azure Portal.
1. Optional. If using Azure AD for US Government or Azure AD China, enter the appropriate **Login API endpoint** and **Graph API endpoint**. The default values work for most organizations.
1. Select **Save changes**.

{{< /tab >}}

{{< /tabs >}}

## Global SAML group memberships lock

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/386390) in GitLab 15.10.

{{< /history >}}

GitLab administrators can use the global SAML group memberships lock to prevent group members from inviting new members to subgroups that have their membership synchronized with SAML Group Links.

Global group memberships lock only applies to subgroups of a top-level group where SAML Group Links synchronization is configured. No user can modify the
membership of a top-level group configured for SAML Group Links synchronization.

When global group memberships lock is enabled:

- Only an administrator can manage memberships of any group including access levels.
- Users cannot:
  - Share a project with other groups.

    {{< alert type="note" >}}

    You cannot set groups or subgroups as [Code Owners](../../project/codeowners/_index.md).
    The Code Owners feature requires direct group memberships, which are not possible when this lock is enabled.

    {{< /alert >}}

  - Invite members to a project created in a group.

To enable global group memberships lock:

1. [Configure SAML](../../../integration/saml.md) for GitLab Self-Managed.
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand the **Visibility and access controls** section.
1. Ensure that **Lock memberships to SAML Group Links synchronization** is selected.
