---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configure access to GitLab Duo.
title: Configure access to GitLab Duo
---

{{< details >}}

- Tier: [Free](../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/583909) in GitLab 18.8.

{{< /history >}}

You can [turn GitLab Duo on or off](../../../user/duo_agent_platform/turn_on_off.md#turn-gitlab-duo-on-or-off)
for a group or restrict access to GitLab Duo for one or more groups.

## Restrict access to GitLab Duo

{{< history >}}

- Default **No group** rule [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225728) in GitLab 18.10.
- **Member access** section and **No group** rule [renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/229785) in GitLab 18.11.

{{< /history >}}

{{< tabs >}}

{{< tab title="On GitLab.com" >}}

Prerequisites:

- The Owner role for the top-level group.

To restrict access to GitLab Duo for a top-level group:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Restrict access based on group membership**, select **Add group**.
1. From the dropdown list, select a group.

   When you select the first group, a default **All eligible users** rule is also added.
   You can use this rule to configure access for all other users.
   This rule is automatically deleted when the group has no access to GitLab Duo Non-Agentic
   or GitLab Duo Agent Platform and all existing groups are removed.

1. Select whether direct members of the group can access
   GitLab Duo Non-Agentic and GitLab Duo Agent Platform.
1. Select **Save changes**.

These settings apply to the following users:

- Users who are direct members of one of the groups
  configured under **Restrict access based on group membership**
  and who execute an AI action in a project or subgroup of the top-level group.
- Users who have the top-level group as the
  [default GitLab Duo namespace](../../../user/profile/preferences.md#set-a-default-gitlab-duo-namespace)
  and who are not members of the top-level group where the AI action is executed.

When you configure access controls, you can select only groups
that are direct subgroups of the top-level group.
You cannot use nested subgroups in access control rules.

{{< /tab >}}

{{< tab title="On GitLab Self-Managed" >}}

Prerequisites:

- Administrator access.

To restrict access to GitLab Duo for an instance:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Restrict access based on group membership**:
   - To add an existing group, select **Add group**.
   - To create a new group, select **Create group**.
1. From the dropdown list, select a group.

   When you select the first group, a default **All eligible users** rule is also added.
   You can use this rule to configure access for all other users.
   This rule is automatically deleted when the group has no access to GitLab Duo Non-Agentic
   or GitLab Duo Agent Platform and all existing groups are removed.

1. Select whether direct members of the group can access
   GitLab Duo Non-Agentic and GitLab Duo Agent Platform.
1. Select **Save changes**.

These settings apply to users who are direct members of one of the groups
configured under **Restrict access based on group membership**.

When you configure access controls, you can select only top-level groups.
You cannot use subgroups in access control rules.

{{< /tab >}}

{{< /tabs >}}

If you do not want to manually manage group membership, you can
[synchronize membership by using LDAP or SAML](#synchronize-group-membership).

### Group membership

When a user is assigned to more than one group,
the user has access to features from all assigned groups.
For example, if a user has access to GitLab Duo Non-Agentic
in group A and GitLab Duo Agent Platform in group B,
the user has access to both sets of features.

If the **All eligible users** rule is configured, the following users
can access both GitLab Duo Non-Agentic and GitLab Duo Agent Platform:

- On GitLab.com: All members of the top-level group.
- On GitLab Self-Managed: All users.

Additional controls (such as disabling features for the top-level group or instance) still apply.

#### Synchronize group membership

If you use LDAP or SAML for authentication, you can synchronize group membership automatically:

1. Configure your LDAP or SAML provider to include a group that represents GitLab Duo Agent Platform users.
1. In GitLab, ensure the group is linked to your LDAP or SAML provider.
1. Group membership updates automatically when users are added or removed from the provider group.

For more information, see:

- [LDAP group synchronization](../../auth/ldap/_index.md)
- [SAML for GitLab Self-Managed](../../../integration/saml.md)
- [SAML for GitLab.com](../../../user/group/saml_sso/_index.md)

## Using access control

You can use access control for phased rollouts or testing and validation.

### Phased rollouts

To implement a phased rollout of GitLab Duo:

1. Create a group for pilot users (for example, `pilot-users`).
1. Add a subset of users to this group.
1. Add more users to the group gradually as you validate functionality and train users.
1. Add all users to the group when you're ready for a full rollout.

### Testing and validation

To test GitLab Duo capabilities in a controlled environment:

1. Create a dedicated group for testing (for example, `agent-testers`).
1. Create a test group or project.
1. Add test users to the `agent-testers` group.
1. Validate functionality and train users before a broader rollout.

## Troubleshooting

### User cannot access GitLab Duo features

A user cannot access GitLab Duo features in the following scenarios:

- Access to GitLab Duo Non-Agentic or GitLab Duo Agent Platform
  is not configured for the group.
- Access to GitLab Duo Non-Agentic or GitLab Duo Agent Platform
  is configured for the group, but one of the following applies:
  - The user is not a direct member of the group.
  - The **All eligible users** rule is not configured.

To resolve this issue, do one of the following:

- Add the user as a direct member to one of the configured groups.
- Give **All eligible users** access to GitLab Duo Non-Agentic or GitLab Duo Agent Platform.
- Remove all group membership access rules.

### GitLab Duo sidebar does not display for certain groups

In GitLab 18.8 and earlier, if you give a group access to GitLab Duo Agent Platform but not to
GitLab Duo Non-Agentic, the GitLab Duo sidebar does not display for members of that group.
As a workaround, ensure the group has access to both
GitLab Duo Non-Agentic and GitLab Duo Agent Platform.

To resolve this issue, upgrade to GitLab 18.9 or later.
