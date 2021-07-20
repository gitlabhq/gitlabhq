---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
---

# Visibility and access controls **(FREE SELF)**

GitLab allows administrators to enforce specific controls.

To access the visibility and access control options:

1. Sign in to GitLab as a user with [Administrator role](../../permissions.md).
1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Settings > General**.
1. Expand the **Visibility and access controls** section.

## Default branch protection

This global option defines the branch protection that applies to every repository's
[default branch](../../project/repository/branches/default.md).
[Branch protection](../../project/protected_branches.md) specifies which roles can push
to branches and which roles can delete branches. In this case _Default_ refers to a
repository's [default branch](../../project/repository/branches/default.md).

This setting applies only to each repositories' default branch. To protect other branches, you must configure branch protection in repository. For details, see [protected branches](../../project/protected_branches.md).

To change the default branch protection:

1. Select the desired option.
1. Click **Save changes**.

For more details, see [Protected branches](../../project/protected_branches.md).

To change this setting for a specific group, see [Default branch protection for groups](../../group/index.md#change-the-default-branch-protection-of-a-group)

### Disable group owners from updating default branch protection **(PREMIUM SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/211944) in GitLab 13.0.

By default, group owners are allowed to override the branch protection set at the global level.

In [GitLab Premium or higher](https://about.gitlab.com/pricing/), GitLab administrators can disable this privilege of group owners.

To do this:

1. Uncheck the **Allow owners to manage default branch protection per group** checkbox.

NOTE:
GitLab administrators can still update the default branch protection of a group.

## Default project creation protection

Project creation protection specifies which roles can create projects.

To change the default project creation protection:

1. Select the desired option.
1. Click **Save changes**.

For more details, see [Specify who can add projects to a group](../../group/index.md#specify-who-can-add-projects-to-a-group).

## Default project deletion protection **(PREMIUM SELF)**

By default, a project can be deleted by anyone with the **Owner** role, either at the project or
group level.

To ensure only Administrator users can delete projects:

1. Check the **Default project deletion protection** checkbox.
1. Click **Save changes**.

## Default deletion delay **(PREMIUM SELF)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/32935) in GitLab 12.6.

By default, a project marked for deletion is permanently removed with immediate effect.
By default, a group marked for deletion is permanently removed after seven days.

WARNING:
The default behavior of [Delayed Project deletion](https://gitlab.com/gitlab-org/gitlab/-/issues/32935) in GitLab 12.6 was changed to
[Immediate deletion](https://gitlab.com/gitlab-org/gitlab/-/issues/220382) in GitLab 13.2.

Projects in a group (but not a personal namespace) can be deleted after a delayed period, by
[configuring in Group Settings](../../group/index.md#enable-delayed-project-removal).
The default period is seven days, and can be changed. Setting this period to `0` enables immediate removal
of projects or groups.

To change this period:

1. Select the desired option.
1. Click **Save changes**.

### Override default deletion delayed period

Alternatively, projects that are marked for removal can be deleted immediately. To do so:

1. [Restore the project](../../project/settings/#restore-a-project).
1. Delete the project as described in the
   [Administering Projects page](../../admin_area/#administering-projects).

## Default project visibility

To set the default visibility levels for new projects:

1. Select the desired default project visibility.
1. Click **Save changes**.

For more details on project visibility, see
[Project visibility](../../../public_access/public_access.md).

## Default snippet visibility

To set the default visibility levels for new snippets:

1. Select the desired default snippet visibility.
1. Click **Save changes**.

For more details on snippet visibility, see
[Project visibility](../../../public_access/public_access.md).

## Default group visibility

To set the default visibility levels for new groups:

1. Select the desired default group visibility.
1. Click **Save changes**.

For more details on group visibility, see
[Group visibility](../../group/index.md#group-visibility).

## Restricted visibility levels

To set the restricted visibility levels for projects, snippets, and selected pages:

1. Select the desired visibility levels to restrict.
1. Select **Save changes**.

For more details on project visibility, see
[Project visibility](../../../public_access/public_access.md).

## Import sources

To specify from which hosting sites users can [import their projects](../../project/import/index.md):

1. Check the checkbox beside the name of each hosting site.
1. Click **Save changes**.

## Project export

To enable project export:

1. Check the **Project export enabled** checkbox.
1. Click **Save changes**.

For more details, see [Exporting a project and its data](../../../user/project/settings/import_export.md#exporting-a-project-and-its-data).

## Enabled Git access protocols

With GitLab access restrictions, you can select with which protocols users can communicate with
GitLab.

Disabling an access protocol does not block access to the server itself by using those ports. The ports
used for the protocol, SSH or HTTP(S), are still accessible. The GitLab restrictions apply at the
application level.

To specify the enabled Git access protocols:

1. Select the desired Git access protocols from the dropdown:
   - Both SSH and HTTP(S)
   - Only SSH
   - Only HTTP(S)
1. Click **Save changes**.

When both SSH and HTTP(S) are enabled, users can choose either protocol.

When only one protocol is enabled:

- The project page shows only the allowed protocol's URL, with no option to
  change it.
- A tooltip is shown when you hover over the URL's protocol, if an action
  on the user's part is required. For example, adding an SSH key or setting a password.

![Project URL with SSH only access](img/restricted_url.png)

On top of these UI restrictions, GitLab denies all Git actions on the protocol
not selected.

WARNING:
GitLab versions [10.7 and later](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/18021),
allow the HTTP(S) protocol for Git clone or fetch requests done by GitLab Runner
from CI/CD jobs, even if **Only SSH** was selected.

## Custom Git clone URL for HTTP(S)

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/18422) in GitLab 12.4.

You can customize project Git clone URLs for HTTP(S), which affects the clone
panel:

![Clone panel](img/clone_panel_v12_4.png)

For example, if:

- Your GitLab instance is at `https://example.com`, then project clone URLs are like
  `https://example.com/foo/bar.git`.
- You want clone URLs that look like `https://git.example.com/gitlab/foo/bar.git` instead,
  you can set this setting to `https://git.example.com/gitlab/`.

![Custom Git clone URL for HTTP](img/custom_git_clone_url_for_https_v12_4.png)

To specify a custom Git clone URL for HTTP(S):

1. Enter a root URL for **Custom Git clone URL for HTTP(S)**.
1. Click on **Save changes**.

NOTE:
SSH clone URLs can be customized in `gitlab.rb` by setting `gitlab_rails['gitlab_ssh_host']` and
other related settings.

## RSA, DSA, ECDSA, ED25519 SSH keys

These options specify the permitted types and lengths for SSH keys.

To specify a restriction for each key type:

1. Select the desired option from the dropdown.
1. Click **Save changes**.

For more details, see [SSH key restrictions](../../../security/ssh_keys_restrictions.md).

## Allow mirrors to be set up for projects

This option is enabled by default. By disabling it, both
[pull and push mirroring](../../project/repository/repository_mirroring.md) no longer
work in every repository. They can only be re-enabled by an administrator user on a per-project basis.

![Mirror settings](img/mirror_settings.png)

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
