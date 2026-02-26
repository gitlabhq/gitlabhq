---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configure access to the GitLab Duo Agent Platform.
title: Configure access to the GitLab Duo Agent Platform
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/583909) in GitLab 18.8.

{{< /history >}}

You can [turn GitLab Duo on or off](../../../user/duo_agent_platform/turn_on_off.md#turn-gitlab-duo-on-or-off) for a group.
You can also specify certain groups that can access only GitLab Duo Agent Platform features.

## Give access to Agent Platform features

{{< tabs >}}

{{< tab title="GitLab Self-Managed" >}}

Prerequisites:

- Administrator access.

To give access to specific Agent Platform features for an instance:

1. In the upper-right corner, select **Admin**.
1. On the left sidebar, select **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Member access**, select **Add group**.
1. From the dropdown list, select an existing group.

   >>> [!note]
   You can select only direct subgroups of the top-level group for access control.
   You cannot use nested subgroups in this configuration.
   >>>

1. Select the features that direct group members can access.
1. Select **Save changes**.

The user can now access these features when they are turned on.

{{< /tab >}}

{{< tab title="GitLab.com" >}}

Prerequisites:

- The Owner role for the top-level group.

To give access to specific Agent Platform features for a top-level group:

1. In the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Member access**, select **Add group**.
1. From the dropdown list, select an existing group.
1. Select the features that direct group members can access.
1. Select **Save changes**.

These settings apply to:

- Users who have the top-level group as the [default GitLab Duo namespace](../../../user/profile/preferences.md#set-a-default-gitlab-duo-namespace).
- Users who execute actions in the top-level group and are direct members of that group.
- Users who are [inherited members](../../../user/project/members/_index.md#membership-types) of the top-level group.

> [!note]
> When you configure group-based access controls, you can select only groups
> that are direct subgroups of the top-level group.
> You cannot use nested subgroups in access control rules.

{{< /tab >}}

{{< /tabs >}}

If you do not want to manually manage group membership, you can
[synchronize membership by using LDAP or SAML](#synchronize-group-membership).

### Group membership

When a user is assigned to more than one group, they access features from all assigned groups.
For example:

- In group A, the user has access to GitLab Duo (Classic) features only.
- In group B, the user has access to flows only.

In this example, the user has access to both GitLab Duo (Classic) features and flows.

If no group is configured:

- On GitLab.com: All members of the top-level group can access Agent Platform features.
- On GitLab Self-Managed: All users can access Agent Platform features.

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

To implement a phased rollout of the Agent Platform:

1. Create a group for pilot users (for example, `pilot-users`).
1. Add a subset of users to this group.
1. Add more users to the group gradually as you validate functionality and train users.
1. Add all users to the group when you're ready for a full rollout.

### Testing and validation

To test Agent Platform capabilities in a controlled environment:

1. Create a dedicated group for testing (for example, `agent-testers`).
1. Create a test namespace or project.
1. Add test users to the `agent-testers` group.
1. Validate functionality and train users before a broader rollout.
