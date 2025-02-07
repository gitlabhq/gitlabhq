---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Free push limit
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

A 100 MiB per-file limit applies when pushing new files to any project in the Free tier.

If a new file that is 100 MiB or larger is pushed to a project in the Free tier, an error is displayed. For example:

```shell
Enumerating objects: 3, done.
Counting objects: 100% (3/3), done.
Delta compression using up to 10 threads
Compressing objects: 100% (2/2), done.
Writing objects: 100% (3/3), 100.03 MiB | 1.08 MiB/s, done.
Total 3 (delta 0), reused 0 (delta 0), pack-reused 0
remote: GitLab: You are attempting to check in one or more files which exceed the 100MiB limit:

- 257cc5642cb1a054f08cc83f2d943e56fd3ebe99 (123 MiB)
- 5716ca5987cbf97d6bb54920bea6adde242d87e6 (396 MiB)

Please refer to https://docs.gitlab.com/ee/user/free_user_limit.html for further information.
To https://gitlab.com/group/my-project.git
 ! [remote rejected] main -> main (pre-receive hook declined)
error: failed to push some refs to 'https://gitlab.com/group/my-project.git'
```

The error lists the unique IDs for files rather than their filename. To look up the filename from the unique identify, run the following command:

```shell
tree -r | grep <id>
```

Because Git is not designed to handle large non-text-based data well, you should use [Git LFS](../topics/git/lfs/_index.md) for these files.
Git LFS is designed to work with Git to track large files.

## Feedback

If you have any feedback to share about this limit, do so in
[issue 428188](https://gitlab.com/gitlab-org/gitlab/-/issues/428188).
