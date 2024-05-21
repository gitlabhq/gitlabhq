---
stage: Secure
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Secret push protection

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Dedicated
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11439) in GitLab 16.7 as an [experiment](../../../../policy/experiment-beta-support.md) for GitLab Dedicated customers.

NOTE:
This feature is an [experiment](../../../../policy/experiment-beta-support.md), available only on GitLab Dedicated, and is subject to the [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

Block secrets such as keys and API tokens from being pushed to your GitLab instance. Secret push protection is triggered when commits are pushed to any repository. If any secrets are detected, the push is blocked.

Push protection is an experiment, and only available on GitLab Dedicated. To use secret detection in your instance, use [pipeline secret detection](../index.md) instead.

## Enable secret push protection

Prerequisites:

- You must be an administrator for your GitLab Dedicated instance.

1. Sign in to your GitLab Dedicated instance as an administrator.
1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Security and Compliance**.
1. Expand **Secret Detection**.
1. Select the **Enable pre-receive secret detection** checkbox.

## Resolve a blocked push

If the blocked secret was added with the most recent commit on your branch:

1. Remove the secrets from the files.
1. Stage the changes with `git add <file-name>`.
1. Modify the most recent commit to include the changed files with `git commit --amend`.
1. Push your changes with `git push`.

If the blocked secret appears earlier in your Git history:

1. Identify the commit SHA from the push error message. If there are multiple, find the earliest using `git log`.
1. Use `git rebase -i <commit-sha>~1` to start an interactive rebase.
1. Mark the offending commits for editing by changing the `pick` command to `edit` in the editor.
1. Remove the secrets from the files.
1. Stage the changes with `git add <file-name>`.
1. Commit the changed files with `git commit --amend`.
1. Continue the rebase with `git rebase --continue` until all secrets are removed.
1. Push your changes with `git push`.

## Skip secret detection

In some cases, it may be necessary to skip push protection. For example, a developer may need to commit a placeholder secret for testing, or a user may want to bypass secret detection due to a Git operation timeout.

There are two ways to skip secret detection for all commits in a push:

- Add `[skip secret detection]` to one of the commit messages. For example:

```shell
# These commits are in the same push. Both will not be scanned.
Add real secret by accident
Add placeholder token to test file [skip secret detection]
```

- Use a [push option](../../../project/push_options.md). For example:

```shell
# These commits are in the same push. Both will not be scanned.
Add real secret by accident
Add placeholder token to test file

git push -o secret_detection.skip_all
```

Skipping secret detection will generate [Project audit event](../../../compliance/audit_events.md#project-audit-events).

NOTE:
[Pipeline secret detection](../index.md) still scans the bypassed secrets when push protection is skipped.

## Troubleshooting

When working with secret push protection, you might encounter the following issues.

### My file was not analyzed

If your file was not scanned, it could be because:

- The blob was binary.
- The blob was larger than 1 MiB.
- The file was renamed, deleted, or moved.
- The content of the commit was identical to the content of another file already present in the source code.
- The file was introduced when the repository was created.
