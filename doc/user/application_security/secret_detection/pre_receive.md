---
stage: Secure
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Pre-receive secret detection **(EXPERIMENT)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11439) in GitLab 16.7 as an [Experiment](../../../policy/experiment-beta-support.md) for GitLab Dedicated customers.

NOTE:
This feature is an [Experiment](../../../policy/experiment-beta-support.md), available only on GitLab Dedicated, and is subject to the [GitLab Testing Agreement](https://about.gitlab.com/handbook/legal/testing-agreement/).

Pre-receive secret detection scans the contents of committed files when they are pushed to a remote repository to prevent the accidental exposure of secrets like keys or API tokens to your repositories. If any secrets are detected, the push is blocked, ensuring that the secrets do not reach your instance.

Pre-receive secret detection is an Experiment, and only available on GitLab Dedicated. To use secret detection in your instance, use [pipeline secret detection](../index.md) instead.

## Enable pre-receive secret detection

Prerequisites:

- You must be an administrator for your GitLab Dedicated instance.

1. Sign into your GitLab Dedicated instance as an administrator.
1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Security and Compliance**.
1. Expand **Secret Detection**.
1. Select the **Enable pre-receive secret detection** checkbox.

## Limitations

This feature only scans non-binary blobs under 1 MiB in size. Binary blobs and blobs larger than 1 MiB are not scanned.

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

In some cases, it may be necessary to skip pre-receive secret detection. For example, a developer may need to commit a placeholder secret for testing, or a user may want to bypass secret detection due to a Git operation timeout. To skip secret detection for a particular secret, add `# gitleaks:allow` to the end of the line. To skip secret detection for all commits in a push, add `[skip secret detection]` to one of the commit messages. For example:

```ruby
# This secret will be skipped due to gitleaks:allow.
FAKE_TOKEN = allowfaketoken123 # gitleaks:allow

# This secret will be scanned, and the push will be rejected.
REAL_TOKEN = rejectrealtoken123
```

```shell
# These commits are in the same push. Both will not be scanned.
Add real secret by accident
Add placeholder token to test file [skip secret detection]
```

NOTE:
[Pipeline secret detection](../index.md) still scans the bypassed secrets when using `[skip secret detection]` in one of your commit messages.
