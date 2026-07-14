---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Control GitLab Duo Agent Platform availability for groups, projects, and instances.
title: Control GitLab Duo Agent Platform availability
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

GitLab Duo Agent Platform is on by default.
Agent Platform includes a [set of features](_index.md).

You can turn Agent Platform on or off:

- On GitLab.com: For top-level groups.
- On GitLab Self-Managed: For instances.

To configure tool governance for Agent Platform, see [agent tool governance](agents/tool-governance.md).

## Turn GitLab Duo Agent Platform on or off

### On GitLab.com

{{< details >}}

- Tier: [Free](../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate

{{< /details >}}

{{< history >}}

- Available on the Free tier on GitLab.com with GitLab Credits in GitLab 18.10.

{{< /history >}}

Prerequisites:

- The Owner role for the top-level group.

To turn Agent Platform on or off for a top-level group:

1. In the top bar, select **Search or go to** and find your top-level group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Under **GitLab Duo Agent Platform**, select or clear the **Turn on GitLab Duo Agentic Chat, agents, and flows** checkbox.
1. Select **Save changes**.

Agent Platform availability changes for all subgroups and projects.

When Agent Platform is turned off, the following features are hidden:

- Related settings for flows and
  [foundational agents](agents/foundational_agents/_index.md#turn-foundational-agents-on-or-off).
- The AI Catalog.

### On GitLab Self-Managed

Prerequisites:

- Administrator access.

To turn Agent Platform on or off for an instance:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **GitLab Duo**.
1. Select **Change configuration**.
1. Under **GitLab Duo Agent Platform**, select or clear the **Turn on GitLab Duo Agentic Chat, agents, and flows** checkbox.
1. Select **Save changes**.

When Agent Platform is turned off, the following features are hidden:

- Related settings for flows,
  [foundational agents](agents/foundational_agents/_index.md#turn-foundational-agents-on-or-off),
  and the GitLab Duo CLI.
- The AI Catalog.

## Lock GitLab Duo on

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/21844) in GitLab 19.1.

{{< /history >}}

Turn GitLab Duo on for all users, regardless of group or project settings.

When you set GitLab Duo availability to **Always on**,
experiment and beta features are not automatically turned on.
To use experiment and beta features, you must
[turn them on separately](#turn-on-beta-and-experimental-features).

{{< tabs >}}

{{< tab title="On GitLab.com" >}}

Prerequisites:

- The Owner role for the top-level group.

To lock GitLab Duo on for a top-level group:

1. In the top bar, select **Search or go to** and find your top-level group.
1. In the left sidebar, select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Under **GitLab Duo availability**, select **Always on**.
1. Select **Save changes**.

GitLab Duo is locked on for all subgroups and projects.
Users with the Owner role for a subgroup or project cannot turn GitLab Duo off.

{{< /tab >}}

{{< tab title="On GitLab Self-Managed" >}}

Prerequisites:

- Administrator access.

To lock GitLab Duo on for an instance:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **GitLab Duo**.
1. Select **Change configuration**.
1. Under **GitLab Duo availability**, select **Always on**.
1. Select **Save changes**.

GitLab Duo is locked on for all groups, subgroups, and projects.
Users with the Owner role for a group, subgroup, or project cannot turn GitLab Duo off.

{{< /tab >}}

{{< /tabs >}}

## Turn GitLab Duo on or off

GitLab Duo is on by default.
You can turn GitLab Duo on or off:

- On GitLab.com: For top-level groups, other groups or subgroups, and projects.
- On GitLab Self-Managed: For instances, groups or subgroups, and projects.

### On GitLab.com

{{< details >}}

- Tier: [Free](../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate

{{< /details >}}

{{< history >}}

- Available on the Free tier on GitLab.com with GitLab Credits in GitLab 18.10.

{{< /history >}}

#### For a top-level group

Prerequisites:

- The Owner role for the top-level group.

To change GitLab Duo availability for a top-level group:

1. In the top bar, select **Search or go to** and find your top-level group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Under **GitLab Duo availability**, select an option.
1. Select **Save changes**.

GitLab Duo availability changes for all subgroups and projects.

#### For a group or subgroup

Prerequisites:

- The Owner role for the group or subgroup.

To change GitLab Duo availability for a group or subgroup:

1. In the top bar, select **Search or go to** and find your group or subgroup.
1. Select **Settings** > **General**.
1. Expand **GitLab Duo features**.
1. Under **GitLab Duo availability**, select an option.
1. Select **Save changes**.

GitLab Duo availability changes for all subgroups and projects.

#### For a project

Prerequisites:

- The Maintainer or Owner role for the project.

To change GitLab Duo availability for a project:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **GitLab Duo**.
1. Turn the **GitLab Duo** toggle on or off.
1. Select **Save changes**.

### On GitLab Self-Managed

#### For an instance

Prerequisites:

- Administrator access.

To change GitLab Duo availability for an instance:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **GitLab Duo**.
1. Select **Change configuration**.
1. Under **GitLab Duo availability**, select an option.
1. Select **Save changes**.

#### For a group or subgroup

Prerequisites:

- The Owner role for the group or subgroup.

To change GitLab Duo availability for a group or subgroup:

1. In the top bar, select **Search or go to** and find your group or subgroup.
1. Select **Settings** > **General**.
1. Expand **GitLab Duo features**.
1. Under **GitLab Duo availability**, select an option.
1. Select **Save changes**.

GitLab Duo availability changes for all subgroups and projects.

#### For a project

Prerequisites:

- The Maintainer or Owner role for the project.

To change GitLab Duo availability for a project:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Settings** > **General**.
1. Expand **GitLab Duo**.
1. Turn the **GitLab Duo** toggle on or off.
1. Select **Save changes**.

## Turn GitLab Duo Core on or off

GitLab Duo Core is included with Premium and Ultimate subscriptions.

- If you are an existing customer from GitLab 17.11 or earlier, you must turn on features for GitLab Duo Core.
- If you are a new customer in GitLab 18.0 or later, GitLab Duo Core is automatically turned on and no further action is needed.

If you were an existing customer with a Premium or Ultimate subscription before May 15, 2025,
when you upgrade to GitLab 18.0 or later, to use GitLab Duo Core, you must turn it on.

### On GitLab.com

{{< details >}}

- Tier: [Free](../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate

{{< /details >}}

{{< history >}}

- Available on the Free tier on GitLab.com with GitLab Credits in GitLab 18.10.

{{< /history >}}

Prerequisites:

- The Owner role for the top-level group.

To change GitLab Duo Core availability for a top-level group:

1. In the top bar, select **Search or go to** and find your top-level group.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Under **GitLab Duo availability**, select an option.
1. Under **GitLab Duo Core**, select or clear the **Turn on features for GitLab Duo Core** checkbox.
   If you selected **Always off** for GitLab Duo availability, you cannot access
   this setting.
1. Select **Save changes**.

It might take up to 10 minutes for the change to take effect.

### On GitLab Self-Managed

Prerequisites:

- Administrator access.

To change GitLab Duo Core availability for an instance:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **GitLab Duo**.
1. Select **Change configuration**.
1. Under **GitLab Duo availability**, select an option.
1. Under **GitLab Duo Core**, select or clear the **Turn on features for GitLab Duo Core** checkbox.
   If you selected **Always off** for GitLab Duo availability, you cannot access
   this setting.
1. Select **Save changes**.

## Turn on beta and experimental features

GitLab Duo features that are experimental and beta are turned off by default.
These features are subject to the [Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

### On GitLab.com

{{< details >}}

- Tier: [Free](../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate

{{< /details >}}

{{< history >}}

- Available on the Free tier on GitLab.com with GitLab Credits in GitLab 18.10.

{{< /history >}}

Prerequisites:

- The Owner role for the top-level group.

To turn on GitLab Duo experiment and beta features for a top-level group:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Feature preview**, select **Turn on experiment and beta GitLab Duo features**.
1. Select **Save changes**.

This setting [cascades to all projects](../project/merge_requests/approvals/settings.md#cascade-settings-from-the-instance-or-top-level-group)
that belong to the group.

### On GitLab Self-Managed

{{< tabs >}}

{{< tab title="In 17.4 and later" >}}

In GitLab 17.4 and later, follow these instructions to turn on GitLab Duo
experiment and beta features for your GitLab Self-Managed instance.

Prerequisites:

- Administrator access.

To turn on GitLab Duo experiment and beta features for an instance:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **GitLab Duo**.
1. Expand **Change configuration**.
1. Under **Feature preview**, select **Use experiment and beta GitLab Duo features**.
1. Select **Save changes**.

{{< /tab >}}

{{< tab title="In 17.3 and earlier" >}}

Prerequisites:

- Administrator access.
- [Network connectivity](../../administration/gitlab_duo/configure/_index.md) enabled.
- [Silent Mode](../../administration/silent_mode/_index.md) turned off.

To turn on GitLab Duo experiment and beta features for an instance:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **GitLab Duo**.
1. Expand **Change configuration**.
1. Under **Feature preview**, select **Use experiment and beta GitLab Duo features**.
1. Select **Save changes**.
1. For GitLab Duo Chat to work immediately,
   [manually synchronize your subscription](../../subscriptions/manage_subscription.md#manually-synchronize-subscription-data).

   If you do not manually synchronize your subscription, it might take up to 24
   hours to activate GitLab Duo Chat on your instance.

{{< /tab >}}

{{< /tabs >}}

## Troubleshooting

When you turn Agent Platform on or off, you might encounter the following issues.

### **Change configuration** missing on GitLab Self-Managed

{{< details >}}

- Offering: GitLab Self-Managed

{{< /details >}}

On GitLab Self-Managed, **Change configuration** might not display.
**Change configuration** appears only when your instance has one of the following:

- An active GitLab Duo Pro, Enterprise, or Self-Hosted add-on with a paid license
- Active GitLab Credits

Without these requirements, you cannot control the availability of GitLab Duo through the UI.
To turn GitLab Duo off, use the Rails console or the API instead.

In a Rails console session, run the following command:

```ruby
ApplicationSetting.current.update!(duo_features_enabled: false, lock_duo_features_enabled: true)
```

To verify the change, run the following command:

```ruby
Gitlab::CurrentSettings.duo_features_enabled    # => false
Gitlab::CurrentSettings.duo_never_on?           # => true
```

Alternatively, send a `PUT` request to the application settings API with an
administrator token that has the `api` scope:

```shell
curl --request PUT \
  --header "PRIVATE-TOKEN: <admin_token>" \
  --data "duo_availability=never_on" \
  "https://<your-gitlab-host>/api/v4/application_settings"
```

You might have to refresh your browser before the GitLab Duo panel disappears.
