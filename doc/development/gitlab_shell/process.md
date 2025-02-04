---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Processes for GitLab Shell
---

## Releasing a new version

GitLab Shell is versioned by Git tags, and the version used by the Rails
application is stored in
[`GITLAB_SHELL_VERSION`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/GITLAB_SHELL_VERSION).

For each version, there is a raw version and a tag version:

- The **raw version** is the version number. For instance, `15.2.8`.
- The **tag version** is the raw version prefixed with `v`. For instance, `v15.2.8`.

To release a new version of GitLab Shell and have that version available to the
Rails application:

1. Create a merge request to update the [`CHANGELOG`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/CHANGELOG.md) with the
   **tag version** and the [`VERSION`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/VERSION) file with the **raw version**.
1. Ask a maintainer to review and merge the merge request. If you're already a
   maintainer, second maintainer review is not required.
1. Add a new Git tag with the **tag version**.
1. Update `GITLAB_SHELL_VERSION` in the Rails application to the **raw
   version**.

   NOTE:
   This can be done as a separate merge request, or in a merge request
   that uses the latest GitLab Shell changes.

## Security releases

GitLab Shell is included in the packages we create for GitLab. Each version of
GitLab specifies the version of GitLab Shell it uses in the `GITLAB_SHELL_VERSION`
file. Because of this specification, security fixes in GitLab Shell are tightly coupled to the
[GitLab patch release](https://handbook.gitlab.com/handbook/engineering/workflow/#security-issues) workflow.

For a security fix in GitLab Shell, two sets of merge requests are required:

1. The fix itself, in the `gitlab-org/security/gitlab-shell` repository and its
   backports to the previous versions of GitLab Shell.
1. Merge requests to change the versions of GitLab Shell included in the GitLab
   patch release, in the `gitlab-org/security/gitlab` repository.

The first step could be to create a merge request with a fix targeting `main`
in `gitlab-org/security/gitlab-shell`. When the merge request is approved by maintainers,
backports targeting previous 3 versions of GitLab Shell must be created. The stable
branches for those versions may not exist, so feel free to ask a maintainer to create
them. The stable branches must be created out of the GitLab Shell tags or versions
used by the 3 previous GitLab releases.

To find out the GitLab Shell version used on a particular GitLab stable release,
run this command, replacing `13-9-stable-ee` with the version you're interested in.
These commands show the version used by the `13.9` version of GitLab:

```shell
git fetch security 13-9-stable-ee
git show refs/remotes/security/13-9-stable-ee:GITLAB_SHELL_VERSION
```

Close to the GitLab patch release, a maintainer should merge the fix and backports,
and cut all the necessary GitLab Shell versions. This allows bumping the
`GITLAB_SHELL_VERSION` for `gitlab-org/security/gitlab`. The GitLab merge request
is handled by the general GitLab patch release process.

After the patch release is done, a GitLab Shell maintainer is responsible for
syncing tags and `main` to the `gitlab-org/gitlab-shell` repository.
