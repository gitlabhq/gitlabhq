---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: yes
description: Control project visibility, creation, retention, and deletion.
title: Control access and visibility
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Administrators of GitLab instances can enforce specific controls on branches, projects, snippets, groups, and more.
For example, you can define:

- Which roles can create or delete projects.
- Retention periods for deleted projects and groups.
- Visibility of groups, projects, and snippets.
- Allowed types and lengths for SSH keys.
- Git settings, such as accepted protocols (SSH or HTTPS) and clone URLs.
- Allow or prevent push mirroring and pull mirroring.

Prerequisites:

- You must be an administrator.

To access the visibility and access control options:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Visibility and access controls**.

## Define which roles can create projects

You can add project creation protections to your instance. These protections define which roles can
[add projects to a group](../../user/group/_index.md#specify-who-can-add-projects-to-a-group)
on the instance.

When you configure the **Default minimum role required to create projects** setting, you set the
default for new groups. Existing groups retain their current permissions.

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Visibility and access controls**.
1. For **Default minimum role required to create projects**, select the desired role:
   - No one.
   - Administrators.
   - Owners.
   - Maintainers.
   - Developers.
1. Select **Save changes**.

{{< alert type="note" >}}

If you select **Administrators** and [Admin Mode](sign_in_restrictions.md#admin-mode)
is enabled, administrators must enter Admin Mode to create new projects.

{{< /alert >}}

## Restrict project deletion to administrators

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Prerequisites:

- You must be an administrator, or have the Owner role in a project.

To restrict project deletion to only administrators:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Visibility and access controls**.
1. Scroll to **Allowed to delete projects**, and select **Administrators**.
1. Select **Save changes**.

To disable the restriction:

1. Select **Owners and administrators**.
1. Select **Save changes**.

## Deletion protection

{{< history >}}

- Enabled delayed deletion for projects by default [on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/393622) and [on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119606) in GitLab 16.0.
- [Changed to default behavior for groups](https://gitlab.com/gitlab-org/gitlab/-/issues/389557) on the Premium and Ultimate tier in GitLab 16.0.
- [Moved](https://gitlab.com/groups/gitlab-org/-/epics/17208) from GitLab Premium to GitLab Free in 18.0.
- [Instance setting](#immediate-deletion) to allow immediate deletion for groups or projects scheduled for deletion [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205556) in GitLab 18.5. Enabled by default. Disabled on GitLab.com and Dedicated.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

These protections help guard against accidental deletion of groups and projects on your instance.

### Retention period

Groups and projects remain restorable during the retention period you define. By default,
the retention period is 30 days, but you can change it to a value between `1` and `90` days.

Prerequisites:

- You must be an administrator.

To configure deletion protection for groups and projects:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Visibility and access controls**.
1. Scroll to **Deletion protection** and set the retention period to a value between `1` and `90` days.
1. Select **Save changes**.

### Immediate deletion

{{< history >}}

- Instance setting to allow immediate deletion for groups or projects scheduled for deletion
  [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/205556) in GitLab 18.5
  [with a flag](../feature_flags/_index.md) named `allow_immediate_namespaces_deletion`.
  Enabled by default on self-managed, but disabled on GitLab.com and Dedicated.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

By default, immediate deletion is allowed for groups and projects marked for deletion. This allows users
to effectively bypass the configured retention period and delete groups or projects immediately.

This can be disabled, so that groups and projects are only deleted automatically after the configured retention period:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Visibility and access controls**.
1. Scroll to **Immediate deletion** and uncheck the checkbox.
1. Select **Save changes**.

{{< alert type="note" >}}

Administrators can always immediately delete groups and projects through the Admin pages.

{{< /alert >}}

### Override defaults and delete immediately

To override the delay, and immediately delete a project marked for removal:

1. [Restore the project](../../user/project/working_with_projects.md#restore-a-project).
1. Delete the project as described in the
   [Administering Projects page](../admin_area.md#administering-projects).

## Configure project visibility defaults

To set the default [visibility levels for new projects](../../user/public_access.md):

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Visibility and access controls**.
1. Select the desired default project visibility:
   - **Private** - Grant project access explicitly to each user. If this
     project is part of a group, grants access to members of the group.
   - **Internal** - Any authenticated user, except external users, can access the project.
   - **Public** - Any user can access the project without any authentication.
1. Select **Save changes**.

## Configure snippet visibility defaults

To set the default visibility levels for new [snippets](../../user/snippets.md):

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Visibility and access controls**.
1. For **Default snippet visibility**, select your desired visibility level:
   - **Private**.
   - **Internal**. This setting is disabled for new projects, groups, and snippets on GitLab.com.
     Existing snippets using the `Internal` visibility setting keep this setting. To learn more
     about this change, see [issue 12388](https://gitlab.com/gitlab-org/gitlab/-/issues/12388).
   - **Public**.
1. Select **Save changes**.

## Configure group visibility defaults

To set the default visibility levels for new groups:

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Visibility and access controls**.
1. For **Default group visibility**, select your desired visibility level:
   - **Private** - Only members can view the group and its projects.
   - **Internal** - Any authenticated user, except external users, can view the group and any internal projects.
   - **Public** - Authentication is not required to view the group and any public projects.
1. Select **Save changes**.

For more details on group visibility, see
[Group visibility](../../user/group/_index.md#group-visibility).

## Restrict visibility levels

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124649) in GitLab 16.3 to prevent restricting default project and group visibility, [with a flag](../feature_flags/_index.md) named `prevent_visibility_restriction`. Disabled by default.
- `prevent_visibility_restriction` [enabled](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131203) by default in GitLab 16.4.
- `prevent_visibility_restriction` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/433280) in GitLab 16.7.

{{< /history >}}

When restricting visibility levels, consider how these restrictions interact
with permissions for subgroups and projects that inherit their visibility from
the item you're changing.

This setting does not apply to projects created under a personal namespace.
There is a [feature request](https://gitlab.com/gitlab-org/gitlab/-/issues/382749) to extend this
functionality to [enterprise users](../../user/enterprise_user/_index.md).

To restrict visibility levels for groups, projects, snippets, and selected pages:

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Visibility and access controls**.
1. For **Restricted visibility levels**, select the desired visibility levels to restrict.
   - If you restrict the **Public** level:
      - Only administrators can create public groups, projects, and snippets.
      - User profiles are visible to only authenticated users through the Web interface.
      - User attributes are not visible through the GraphQL API.
   - If you restrict the **Internal** level:
     - Only administrators can create internal groups, projects, and snippets.
   - If you restrict the **Private** level:
     - Only administrators can create private groups, projects, and snippets.
1. Select **Save changes**.

{{< alert type="note" >}}

You cannot restrict a visibility level that is set as the default for new projects or groups.
Conversely, you cannot set a restricted visibility level as the default for new projects or groups.

{{< /alert >}}

## Configure enabled Git access protocols

With GitLab access restrictions, you can select the protocols users can use to
communicate with GitLab. Disabling an access protocol does not block port access to the
server itself. The ports used for the protocol, SSH or HTTP(S), are still accessible.
The GitLab restrictions apply at the application level.

GitLab allows Git actions only for the protocols you select:

- If you enable both SSH and HTTP(S), users can choose either protocol.
- If you enable only one protocol, project pages show only the allowed protocol's
  URL, with no option to change it.

To specify the enabled Git access protocols for all projects on your instance:

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Visibility and access controls**.
1. For **Enabled Git access protocols**, select your desired protocols:
   - Both SSH and HTTP(S).
   - Only SSH.
   - Only HTTP(S).
1. Select **Save changes**.

{{< alert type="warning" >}}

GitLab [allows the HTTP(S) protocol](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/18021)
for Git clone or fetch requests performed [with GitLab CI/CD job tokens](../../ci/jobs/ci_job_token.md).
This happens even if you select **Only SSH**, because GitLab Runner and CI/CD jobs require this setting.

{{< /alert >}}

## Customize Git clone URL for HTTP(S)

{{< details >}}

- Offering: GitLab Self-Managed

{{< /details >}}

You can customize project Git clone URLs for HTTP(S), which affects the clone
panel shown to users on a project's page. For example, if:

- Your GitLab instance is at `https://example.com`, then project clone URLs are like
  `https://example.com/foo/bar.git`.
- You want clone URLs that look like `https://git.example.com/gitlab/foo/bar.git` instead,
  you can set this setting to `https://git.example.com/gitlab/`.

To specify a custom Git clone URL for HTTP(S) in `gitlab.rb`, set a new value for
`gitlab_rails['gitlab_ssh_host']`. To specify a new value from the GitLab UI:

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Visibility and access controls**.
1. Enter a root URL for **Custom Git clone URL for HTTP(S)**.
1. Select **Save changes**.

## Configure defaults for RSA, DSA, ECDSA, ED25519, ECDSA_SK, ED25519_SK SSH keys

These options specify the [permitted types and lengths](../../security/ssh_keys_restrictions.md) for SSH keys.

To specify a restriction for each key type:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Visibility and access controls**.
1. Go to **RSA SSH keys**.
1. For each key type, you can allow or prevent their use entirely, or allow only lengths of:
   - At least 1024 bits.
   - At least 2048 bits.
   - At least 3072 bits.
   - At least 4096 bits.
   - At least 1024 bits.
1. Select **Save changes**.

## Enable project mirroring

GitLab enables project mirroring by default. If you disable it, both
[pull mirroring](../../user/project/repository/mirror/pull.md) and
[push mirroring](../../user/project/repository/mirror/push.md) no longer
work in every repository. They can only be re-enabled by an administrator user on a per-project basis.

To allow project maintainers on your instance to configure mirroring per project:

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **Repository**.
1. Expand **Repository mirroring**.
1. Select **Allow project maintainers to configure repository mirroring**.
1. Select **Save changes**.

## Configure globally-allowed IP address ranges

Administrators can combine IP address ranges with
[IP restrictions per group](../../user/group/access_and_permissions.md#restrict-group-access-by-ip-address).
Globally-allowed IP addresses enable aspects of the GitLab installation to work properly, even when
groups set their own IP address restrictions.

For example, if the GitLab Pages daemon runs on the `10.0.0.0/24` range, globally allow that range.
GitLab Pages can still fetch artifacts from pipelines, even if IP address restrictions for the group don't
include the `10.0.0.0/24` range.

To add a IP address range to the allowlist for a group:

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Visibility and access controls**.
1. In **Globally-allowed IP ranges**, provide a list of IP address ranges. This list:
   - Has no limit on the number of IP address ranges.
   - Applies to both SSH or HTTP authorized IP address ranges. You cannot split
     this list by authorization type.
1. Select **Save changes**.

## Prevent invitations to groups and projects

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/189954) in GitLab 18.0. Disabled by default.

{{< /history >}}

Administrators can prevent non-administrators from inviting users to all groups or projects on the instance.
When you configure this setting, only administrators can invite users to groups or projects on the instance.

{{< alert type="note" >}}

Features such as [sharing](../../user/project/members/sharing_projects_groups.md) or [migrations](../../user/project/import/_index.md) can still allow access to these groups and projects.

{{< /alert >}}

Prerequisites:

- You must be an administrator.

To prevent invitations:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **Visibility and access controls**.
1. Select the **Prevent group member invitations** checkbox.
1. Select **Save changes**.
