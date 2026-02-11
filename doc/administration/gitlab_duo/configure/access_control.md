---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Configure access for the GitLab Duo Agent Platform.
title: Configure access for the Agent Platform
---

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/583909) in GitLab 18.8.

{{< /history >}}

You can [turn GitLab Duo on or off for a group](../../../user/gitlab_duo/turn_on_off.md).

In addition, you can specify specific groups that can access Agent Platform features only.

## Give a user access to Agent Platform features

To give a user access to specific Agent Platform features, complete the following steps.

{{< tabs >}}

{{< tab title="For an instance" >}}

Prerequisites:

- You must be an administrator.

To give a user access to specific features:

1. In the upper-right corner, select **Admin**.
1. On the left sidebar, select **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Member Access**, select **Add group**.
1. Use the search box to select an existing group.

   >>> [!note]
   You can select only direct subgroups of the top-level group for access control.
   You cannot use nested subgroups in this configuration.
   >>>

1. Select the features that direct group members can access.
1. Select **Save changes**.

The user now has access to these features anywhere in the instance
that they have access and the features are turned on.

{{< /tab >}}

{{< tab title="For GitLab.com" >}}

Prerequisites:

- You must be an administrator of the top-level namespace.
- An existing group or the ability to create a new group for DAP users.

To give a user access to specific features:

1. In the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Member Access**, select **Add group**.
1. Use the search box to select an existing group.
1. Select the features that direct group members can access.
1. Select **Save changes**.

These settings apply to:

- Users who have the top-level group as the [default GitLab Duo namespace](../../../user/profile/preferences.md#set-a-default-gitlab-duo-namespace).
- Users who do not have access through their default namespace
  but can use the features through their top-level group.
- Users who are direct members of the top-level group.

> [!note]
> When you configure group-based access controls, you can select only groups
> that are direct subgroups of the top-level group.
> You cannot use nested subgroups in access control rules.

{{< /tab >}}

{{< /tabs >}}

If you do not want to manually manage group membership, you can
[synchronize membership by using LDAP or SAML](#synchronize-group-membership).

### Multiple group membership

When a user is assigned to more than one group, they get the features from all assigned groups.
For example:

- In group A, they have access to classic features only.
- In group B, they have access to flows only.

They will be able to access both classic features and flows.

### When no group is configured

If no group is configured:

- On GitLab.com: All members of the top-level namespace are eligible to use Duo Agent Platform features. Further controls (such as disabling features across the namespace) are still applied.
- On GitLab Self-Managed: All users in the instance are eligible to use Agent Platform features.

In all scenarios, further controls such as disabling features across a namespace or instance still apply.

### Synchronize group membership

If you use LDAP or SAML for authentication, you can synchronize group membership automatically:

1. Configure your LDAP or SAML provider to include a group that represents DAP users.
1. In GitLab, ensure the group is linked to your LDAP/SAML provider.
1. Group membership updates automatically when users are added or removed from the provider group.

For more information, see:

- [LDAP group synchronization](../../auth/ldap/_index.md)
- [SAML for GitLab Self-Managed](../../../integration/saml.md)
- [SAML for GitLab.com](../../../user/group/saml_sso/_index.md)

## Use cases

You can use groups to implement phased rollouts or for testing purposes.

### Phased rollout

To implement a phased rollout of the Agent Platform:

1. Create a group for pilot users (for example, `pilot-users`).
1. Add a subset of users to this group.
1. Gradually add more users to the group as you validate functionality and train users.
1. When ready for full rollout, add all users to the group.

### Testing and validation

To test Agent Platform capabilities in a controlled environment:

1. Create a dedicated group for testing (for example, `agent-testers`).
1. Create a test namespace or project.
1. Add test users to the `agent-testers` group.
1. Validate functionality and train users before broader rollout.

## Related topics

- [Turn on GitLab Duo](../../../user/gitlab_duo/turn_on_off.md)
