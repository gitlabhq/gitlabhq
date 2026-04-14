---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configure access to the GitLab Duo Agent Platform.
title: Configure access to the GitLab Duo Agent Platform
---

{{< details >}}

- Tier: [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier-on-gitlabcom), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/583909) in GitLab 18.8.

{{< /history >}}

You can [turn GitLab Duo on or off](../../../user/duo_agent_platform/turn_on_off.md#turn-gitlab-duo-on-or-off) for a group,
or restrict access to GitLab Duo and Agent Platform to specific groups only.

## Give access to Agent Platform features

{{< history >}}

- Default **No group** rule [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225728) in GitLab 18.10.
- **Member access** section and **No group** rule [renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/229785) in GitLab 18.11.

{{< /history >}}

{{< tabs >}}

{{< tab title="On GitLab.com" >}}

Prerequisites:

- The Owner role for the top-level group.

To give access to specific Agent Platform features for a top-level group:

1. In the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Limit access based on group membership**, select **Add group**.
1. From the dropdown list, select an existing subgroup.

   When you add the first group, a default **All eligible users** rule is also added.
   You can use this rule to configure access for all other users.
   This rule is automatically deleted when it has no access to GitLab Duo
   or Agent Platform and all existing groups are removed.

1. Select the features that direct group members can access.
1. Select **Save changes**.

These settings apply to:

- Users who are direct members of one of the configured groups under **Limit access based on group membership**, and they are executing an AI action in a project or group within this top-level group.
- Users who have the top-level group as the [default GitLab Duo namespace](../../../user/profile/preferences.md#set-a-default-gitlab-duo-namespace), and they are not a member of the top-level group where the AI action is taking place.

When you configure group-based access controls, you can select only groups that are direct subgroups of the top-level group. You cannot use nested subgroups in access control rules.

> [!note]
> If groups are configured, users must be direct members of one of those groups to have access to GitLab Duo and Agent Platform features or you can use the **All eligible users** configuration. Access is additionally determined by other access methods.
{{< /tab >}}

{{< tab title="On GitLab Self-Managed" >}}

Prerequisites:

- Administrator access.

To give access to specific Agent Platform features for an instance:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Limit access based on group membership**, select **Add group**.
1. From the dropdown list, select an existing group.

   When you add the first group, a default **All eligible users** rule is also added.
   You can use this rule to configure access for all other users.
   This rule is automatically deleted when it has no access to GitLab Duo
   or Agent Platform and all existing groups are removed.

1. Select the features that direct group members can access.
1. Select **Save changes**.

These settings apply to users who are direct members of one of the configured groups under **Limit access based on group membership**. The user can now access these features when they are turned on.

When you configure group-based access controls, you can select only top-level groups. You cannot use subgroups in access control rules.

> [!note]
> If groups are configured, users must be direct members of one of those groups to have access to GitLab Duo and Agent Platform features or you can use the **All eligible users** configuration. Access is additionally determined by other access methods.
{{< /tab >}}

{{< /tabs >}}

If you do not want to manually manage group membership, you can
[synchronize membership by using LDAP or SAML](#synchronize-group-membership).

### Group membership

When a user is assigned to more than one group, they access features from all assigned groups.
For example:

- In group A, the user has access to GitLab Duo features only.
- In group B, the user has access to Agent Platform only.

In this example, the user has access to both GitLab Duo features and Agent Platform.

If **All eligible users** is configured:

- On GitLab.com: All members of the top-level group can access GitLab Duo and Agent Platform features.
- On GitLab Self-Managed: All users can access GitLab Duo and Agent Platform features.

Additional controls (such as disabling features for the top-level group or instance) still apply.

#### Synchronize group membership

If you use LDAP or SAML for authentication, you can synchronize group membership automatically:

1. Configure your LDAP or SAML provider to include a group that represents Agent Platform users.
1. In GitLab, ensure the group is linked to your LDAP or SAML provider.
1. Group membership updates automatically when users are added or removed from the provider group.

For more information, see:

- [LDAP group synchronization](../../auth/ldap/_index.md)
- [SAML for GitLab Self-Managed](../../../integration/saml.md)
- [SAML for GitLab.com](../../../user/group/saml_sso/_index.md)

## Using access control

You can use access control for phased rollouts or testing and validation.

### Phased rollouts

To implement a phased rollout of GitLab Duo or Agent Platform:

1. Create a group for pilot users (for example, `pilot-users`).
1. Add a subset of users to this group.
1. Add more users to the group gradually as you validate functionality and train users.
1. Add all users to the group when you're ready for a full rollout.

### Testing and validation

To test GitLab Duo or Agent Platform capabilities in a controlled environment:

1. Create a dedicated group for testing (for example, `agent-testers`).
1. Create a test group or project.
1. Add test users to the `agent-testers` group.
1. Validate functionality and train users before a broader rollout.

## Troubleshooting

### User cannot access GitLab Duo or Agent Platform features

If a user cannot access GitLab Duo or Agent Platform features, it might be because GitLab Duo or Agent Platform is either:

- Not configured for the group the user is a direct member of.
- Configured, but either:
  - The user is not a direct member of the group.
  - The **All eligible users** rule is not configured accordingly.

To resolve this issue, either:

- Add the user to a configured group: Add the user as a direct member to one of the configured groups.
- Activate GitLab Duo or Agent Platform for the **All eligible users** rule, so that users who are not members of the group receive access to the features.
- Remove all group membership access rules.

### GitLab Duo sidebar does not display for certain groups

In GitLab 18.8 and earlier, if you give a group access to Agent Platform but not to
GitLab Duo, the GitLab Duo sidebar does not display for members of that group.
As a workaround, ensure the group has access to both
GitLab Duo and Agent Platform features.

To resolve this issue, upgrade to GitLab 18.9 or later.
