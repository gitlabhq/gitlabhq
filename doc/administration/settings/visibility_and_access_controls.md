---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Control project visibility, creation, retention, and deletion on GitLab Self-Managed."
title: Control access and visibility
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

GitLab enables users with administrator access to enforce
specific controls on branches, projects, snippets, groups, and more.

Prerequisites:

- You must be an administrator.

To access the visibility and access control options:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Visibility and access controls**.

## Define which roles can create projects

You can add project creation protections to your instance. These protections define which roles can
[add projects to a group](../../user/group/_index.md#specify-who-can-add-projects-to-a-group)
on the instance. To alter which roles have permission to create projects:

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Visibility and access controls**.
1. For **Default project creation protection**, select the desired roles:
   - No one.
   - Administrators.
   - Owners.
   - Maintainers.
   - Developers and Maintainers.
1. Select **Save changes**.

NOTE:
If you select **Administrators** and [Admin Mode](sign_in_restrictions.md#admin-mode)
is turned on, administrators must enter Admin Mode to create new projects.

## Restrict project deletion to administrators

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

> - User interface [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/352960) in GitLab 15.1.

Prerequisites:

- You must be an administrator, or have the **Owner** role in a project.

To restrict project deletion to only administrators:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Visibility and access controls**.
1. Scroll to:
   - (GitLab 15.1 and later) **Allowed to delete projects**, and select **Administrators**.
   - (GitLab 15.0 and earlier) **Default project deletion protection**, and select **Only admins can delete project**.
1. Select **Save changes**.

To disable the restriction:

1. Select **Owners and administrators**.
1. Select **Save changes**.

## Deletion protection

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/352960) from default delayed project deletion in GitLab 15.1.
> - [Enabled for projects in personal namespaces](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89466) in GitLab 15.1.
> - [Disabled for projects in personal namespaces](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95495) in GitLab 15.3.
> - [Removed option to delete immediately](https://gitlab.com/gitlab-org/gitlab/-/issues/389557) in GitLab 15.11 [with a flag](../feature_flags.md) named `always_perform_delayed_deletion`. Disabled by default.
> - Enabled delayed deletion by default and removed the option to delete immediately [on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/393622) and [on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119606) in GitLab 16.0.

These protections help guard against accidental deletion of groups and projects on your instance.

### Retention period

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/352960) in GitLab 15.1.

Groups and projects remain restorable during the retention period you define. By default,
this is 7 days, but you can change it. If you set the retention period to `0` days, GitLab
removes deleted groups and projects immediately. You can't restore them.

In GitLab 15.1 and later, the retention period must be between `1` and `90` days.
If, before the 15.1 update, you set the retention period to `0` days, the next time you change
any application setting, GitLab:

- Changes the retention period to `1` day.
- Disables deletion protection.

### Delayed project deletion

> - User interface [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/352960) in GitLab 15.1.
> - Enabled delayed deletion by default and removed the option to delete immediately [on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/393622) and [on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119606) in GitLab 16.0.

Prerequisites:

- You must be an administrator.
- You must enable delayed project deletion for groups before you can enable it for projects.
  Deletion protection is not available for projects only.
- When disabled, GitLab 15.1 and later enforces this delayed-deletion setting, and you can't override it.

To configure delayed project deletion:

::Tabs

:::TabTitle GitLab 16.0 and later

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Visibility and access controls**.
1. Scroll to **Deletion protection** and set the retention period to a value between `1` and `90` days.
1. Select **Save changes**.

:::TabTitle GitLab 15.11 and earlier

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Visibility and access controls**.
1. Scroll to:
   - In GitLab 15.11 with `always_perform_delayed_deletion` feature flag enabled: **Deletion protection** and set the retention period to a value between `1` and `90` days.
   - In GitLab 15.1 to 15.10: **Deletion protection** and select **Keep deleted groups and projects**, then set the retention period.
   - In GitLab 15.0 and earlier: **Default delayed project protection** and select **Enable delayed project deletion by
     default for newly-created groups**, then set the retention period.
1. Select **Save changes**.

::EndTabs

### Delayed group deletion

> - User interface [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352960) in GitLab 15.1.
> - [Changed to default behavior](https://gitlab.com/gitlab-org/gitlab/-/issues/389557) on the Premium and Ultimate tier in GitLab 16.0.

Groups remain restorable if the retention period is `1` or more days.

In GitLab 16.0 and later, the **Keep deleted** option is removed, and delayed group deletion is the default.

To enable delayed group deletion in GitLab 15:

1. GitLab 15.11 only: enable the `always_perform_delayed_deletion` feature flag.
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Visibility and access controls**.
1. For **Deletion projection**, select **Keep deleted**.
1. Select **Save changes**.

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
1. Select **Settings > General**.
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
1. Select **Settings > General**.
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
1. Select **Settings > General**.
1. Expand **Visibility and access controls**.
1. For **Default group visibility**, select your desired visibility level:
   - **Private** - Only members can view the group and its projects.
   - **Internal** - Any authenticated user, except external users, can view the group and any internal projects.
   - **Public** - Authentication is not required to view the group and any public projects.
1. Select **Save changes**.

For more details on group visibility, see
[Group visibility](../../user/group/_index.md#group-visibility).

## Restrict visibility levels

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124649) in GitLab 16.3 to prevent restricting default project and group visibility, [with a flag](../feature_flags.md) named `prevent_visibility_restriction`. Disabled by default.
> - `prevent_visibility_restriction` [enabled](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/131203) by default in GitLab 16.4.
> - `prevent_visibility_restriction` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/433280) in GitLab 16.7.

When restricting visibility levels, consider how these restrictions interact
with permissions for subgroups and projects that inherit their visibility from
the item you're changing.

This setting does not apply to groups and projects created under a personal namespace.
There is a [feature request](https://gitlab.com/gitlab-org/gitlab/-/issues/382749) to extend this
functionality to [enterprise users](../../user/enterprise_user/_index.md).

To restrict visibility levels for groups, projects, snippets, and selected pages:

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Visibility and access controls**.
1. For **Restricted visibility levels**, select the desired visibility levels to restrict.
   - If you restrict the **Public** level:
      - Only administrators can create public groups, projects, and snippets.
      - User profiles are visible to only authenticated users through the Web interface.
      - User attributes through the GraphQL API are:
         - Not visible in [GitLab 15.1 and later](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88020).
         - Visible only to authenticated users in GitLab 15.0.
   - If you restrict the **Internal** level:
     - Only administrators can create internal groups, projects, and snippets.
   - If you restrict the **Private** level:
     - Only administrators can create private groups, projects, and snippets.
1. Select **Save changes**.

NOTE:
You cannot restrict a visibility level that is set as the default for new projects or groups.
Conversely, you cannot set a restricted visibility level as the default for new projects or groups.

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
1. Select **Settings > General**.
1. Expand **Visibility and access controls**.
1. For **Enabled Git access protocols**, select your desired protocols:
   - Both SSH and HTTP(S).
   - Only SSH.
   - Only HTTP(S).
1. Select **Save changes**.

WARNING:
GitLab [allows the HTTP(S) protocol](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/18021)
for Git clone or fetch requests performed [with GitLab CI/CD job tokens](../../ci/jobs/ci_job_token.md).
This happens even if you select **Only SSH**, because GitLab Runner and CI/CD jobs require this setting.

## Customize Git clone URL for HTTP(S)

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
1. Select **Settings > General**.
1. Expand **Visibility and access controls**.
1. Enter a root URL for **Custom Git clone URL for HTTP(S)**.
1. Select **Save changes**.

## Configure defaults for RSA, DSA, ECDSA, ED25519, ECDSA_SK, ED25519_SK SSH keys

These options specify the [permitted types and lengths](../../security/ssh_keys_restrictions.md) for SSH keys.

To specify a restriction for each key type:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
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
1. Select **Settings > Repository**.
1. Expand **Repository mirroring**.
1. Select **Allow project maintainers to configure repository mirroring**.
1. Select **Save changes**.

## Configure globally-allowed IP address ranges

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87579) in GitLab 15.1 [with a flag](../feature_flags.md) named `group_ip_restrictions_allow_global`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/366445) in GitLab 15.4. [Feature flag `group_ip_restrictions_allow_global`](https://gitlab.com/gitlab-org/gitlab/-/issues/366445) removed.

Administrators can combine IP address ranges with
[IP restrictions per group](../../user/group/access_and_permissions.md#restrict-group-access-by-ip-address).
Use globally-allowed IP addresses to allow aspects of the GitLab installation to work even when IP address
restrictions are set per group.

For example, if the GitLab Pages daemon runs on the `10.0.0.0/24` range, you can specify that range as globally allowed.
GitLab Pages can still fetch artifacts from pipelines, even if IP address restrictions for the group don't
include the `10.0.0.0/24` range.

To add a IP address range to the allowlist for a group:

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **Visibility and access controls**.
1. In **Globally-allowed IP ranges**, provide a list of IP address ranges. This list:
   - Has no limit on the number of IP address ranges.
   - Applies to both SSH or HTTP authorized IP address ranges. You cannot split
     this list by authorization type.
1. Select **Save changes**.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
