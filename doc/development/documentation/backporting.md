---
stage: none
group: Documentation Guidelines
info: For assistance with this Style Guide page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
title: Backport documentation changes
---

There are two types of backports:

- **Current stable release**: Any maintainer can backport
  changes, usually bug fixes but also important documentation changes, into the
  current stable release.
- **Older stable releases**: To guarantee the
  [maintenance policy](../../policy/maintenance.md) is respected, merging to
  older stable releases is restricted to release managers.

## Backport documentation changes to current stable release

To backport documentation changes to the current stable release,
follow the [standard process to contribute to documentation](_index.md).

## Backport documentation changes to older releases

{{< alert type="warning" >}}

You should only rarely consider backporting documentation to older stable releases. Legitimate reasons to backport documentation include legal issues, emergency security fixes, and fixes to content that might prevent users from upgrading or cause data loss.

{{< /alert >}}

To backport documentation changes in documentation releases older than the
current stable branch:

1. [Create an issue for the backport.](#create-an-issue)
1. [Create the merge request (MR) to backport the change.](#create-the-merge-request-to-backport-the-change)
1. [Deploy the backport change.](#deploy-the-backport-changes)

### Create an issue

Prerequisites:

- The person requesting the backport does this step. You must have at
  least the Developer role for the [Technical Writing team tasks project](https://gitlab.com/gitlab-org/technical-writing/team-tasks).

1. Open an [issue in the Technical Writing team tasks project](https://gitlab.com/gitlab-org/technical-writing/team-tasks/-/issues/new)
using the [backport changes template](https://gitlab.com/gitlab-org/technical-writing/team-tasks/-/blob/main/.gitlab/issue_templates/backport_changes.md).

1. In the issue, state why the backport is needed. Include:
   - The background to this change.
   - Which specific documentation versions are changing.
   - How the documentation will change.
   - Links to any supporting issues or MRs.

1. Ask for the approval of technical writing leadership by creating a comment in
   this issue with the following text:

   ```plaintext
   @gitlab-org/tw-leadership could I get your approval for this documentation backport?
   ```

After the technical writing leadership approves the backport, you can create the
merge request to backport the change.

### Create the merge request to backport the change

Prerequisites:

- The person requesting the backport does this step. You must have at least the
  Developer role on the project that needs the backport.

To backport a change, merge your changes into the stable branch of the version
where you want the changes to occur.

1. Open an MR with the backport by following the
   [release docs guidelines](https://gitlab.com/gitlab-org/release/docs/-/blob/master/general/patch/engineers.md#backporting-a-bug-fix-in-the-gitlab-project),
   and mention the issue you opened before so that they are linked.

1. Assign the MR to a technical writer for review.

1. After the technical writer approves the MR, assign the MR to a release manager
   for review and merge.

   Mention this issue to the release manager, and provide them with all the context
   they need.

For the change to appear in:

- `docs.gitlab.com`, the release manager only has to merge the MR to the stable branch,
  and the technical writer needs to [deploy the backport changes](#deploy-the-backport-changes).
- `gitlab.com/help`, the change needs to be part of a GitLab release. The release
  manager can include the change in the next release they create. This step is optional.

### Deploy the backport changes

Prerequisites:

- The technical writer assigned to the backport does this step. You must have at
  least the Maintainer role for the [Technical Writing team tasks project](https://gitlab.com/gitlab-org/technical-writing/team-tasks).

After the changes are merged to the appropriate stable branch,
you must deploy the backported changes.

#### Backport changes made in GitLab 17.9 and later

Run a [new pipeline](https://gitlab.com/gitlab-org/technical-writing/docs-gitlab-com/-/pipelines/new)
in `docs-gitlab-com`. Choose the branch name that matches the stable version, for example `17.9`.

- A parallel deployment for that branch is run and is deployed automatically.
- A Docker image is created that contains the versioned documentation and can
  be used offline.

#### Backport changes made in GitLab 17.8 and earlier

Run a [new pipeline](https://gitlab.com/gitlab-org/gitlab-docs/-/pipelines/new)
in `gitlab-docs`. Choose the branch name that matches the stable version, for example `17.8` or `16.0`.

- A Docker image is created that contains the versioned documentation and can
  be used offline.

#### Backport changes made to a version other than the last three stable branches

If the backport change was made to a version other than the last three stable
branches, update the docs archives site:

1. Make sure the Docker images from the previous instructions are built.
1. Run a [new pipeline](https://gitlab.com/gitlab-org/gitlab-docs-archives/-/pipelines/new)
   in the `gitlab-docs-archives` repository.
1. After the pipeline finishes, go to `https://archives.docs.gitlab.com` and verify
   that the changes are available for the correct version.

## View older documentation versions

Previous versions of the documentation are available on `docs.gitlab.com`.
To view a previous version, in the upper-right corner, select the version
number from the dropdown list.

To view versions that are not available on `docs.gitlab.com`:

- View the [documentation archives](https://archives.docs.gitlab.com).
- Go to the GitLab repository and select the version-specific branch. For example,
  the [13.2 branch](https://gitlab.com/gitlab-org/gitlab/-/tree/13-2-stable-ee/doc) has the
  documentation for GitLab 13.2.
