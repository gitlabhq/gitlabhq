---
type: reference
---

# Visibility and access controls **(CORE ONLY)**

GitLab allows administrators to enforce specific controls.

To access the visibility and access control options:

1. Log in to GitLab as an admin.
1. Go to **Admin Area > Settings > General**.
1. Expand the **Visibility and access controls** section.

## Default branch protection

This global option defines the branch protection that applies to every repository's default branch. [Branch protection](../../project/protected_branches.md) specifies which roles can push to branches and which roles can delete
branches.  In this case _Default_ refers to a repository's default branch, which in most cases is _master_.
branches.  "Default" in this case refers to a repository's default branch, which in most cases would be "master".

This setting applies only to each repositories' default branch. To protect other branches, you must configure branch protection in repository. For details, see [Protected Branches](../../project/protected_branches.md).

To change the default branch protection:

1. Select the desired option.
1. Click **Save changes**.

For more details, see [Protected branches](../../project/protected_branches.md).

## Default project creation protection

Project creation protection specifies which roles can create projects.

To change the default project creation protection:

1. Select the desired option.
1. Click **Save changes**.

For more details, see [Default project-creation level](../../group/index.md#default-project-creation-level).

## Default project deletion protection

By default, a project can be deleted by anyone with the **Owner** role, either at the project or
group level.

To ensure only admin users can delete projects:

1. Check the **Default project deletion protection** checkbox.
1. Click **Save changes**.

## Default project visibility

To set the default visibility levels for new projects:

1. Select the desired default project visibility.
1. Click **Save changes**.

For more details on project visibility, see [Public access](../../../public_access/public_access.md).

## Default snippet visibility

To set the default visibility levels for new snippets:

1. Select the desired default snippet visibility.
1. Click **Save changes**.

For more details on snippet visibility, see [Public access](../../../public_access/public_access.md).

## Default group visibility

To set the default visibility levels for new groups:

1. Select the desired default group visibility.
1. Click **Save changes**.

For more details on group visibility, see [Public access](../../../public_access/public_access.md).

## Restricted visibility levels

To set the available visibility levels for new projects and snippets:

1. Check the desired visibility levels.
1. Click **Save changes**.

For more details on project visibility, see [Public access](../../../public_access/public_access.md).

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

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/4696) in GitLab 8.10.

With GitLab's access restrictions, you can select with which protocols users can communicate with
GitLab.

Disabling an access protocol does not block access to the server itself via those ports. The ports
used for the protocol, SSH or HTTP(S), will still be accessible. The GitLab restrictions apply at the
application level.

To specify the enabled Git access protocols:

1. Select the desired Git access protocols from the dropdown:
   - Both SSH and HTTP(S)
   - Only SSH
   - Only HTTP(S)
1. Click **Save changes**.

When both SSH and HTTP(S) are enabled, users can choose either protocol.

When only one protocol is enabled:

- The project page will only show the allowed protocol's URL, with no option to
  change it.
- A tooltip will be shown when you hover over the URL's protocol, if an action
  on the user's part is required, e.g. adding an SSH key, or setting a password.

![Project URL with SSH only access](img/restricted_url.png)

On top of these UI restrictions, GitLab will deny all Git actions on the protocol
not selected.

CAUTION: **Important:**
Starting with [GitLab 10.7](https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/18021),
HTTP(S) protocol will be allowed for Git clone or fetch requests done by GitLab Runner
from CI/CD jobs, even if _Only SSH_ was selected.

## Custom Git clone URL for HTTP(S)

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/18422) in GitLab 12.4.

You can customize project Git clone URLs for HTTP(S). This will affect the clone
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

NOTE: **Note:**
SSH clone URLs can be customized in `gitlab.rb` by setting `gitlab_rails['gitlab_ssh_host']` and
other related settings.

## RSA, DSA, ECDSA, ED25519 SSH keys

These options specify the permitted types and lengths for SSH keys.

To specify a restriction for each key type:

1. Select the desired option from the dropdown.
1. Click **Save changes**.

For more details, see [SSH key restrictions](../../../security/ssh_keys_restrictions.md).

## Allow mirrors to be set up for projects

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/3586) in GitLab 10.3.

This option is enabled by default. By disabling it, both [pull and push mirroring](../../project/repository/repository_mirroring.md) will no longer
work in every repository and can only be re-enabled by an admin on a per-project basis.

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
