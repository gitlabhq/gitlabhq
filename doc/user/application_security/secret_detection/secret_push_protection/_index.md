---
stage: Application Security Testing
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Secret push protection
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11439) in GitLab 16.7 as an [experiment](../../../../policy/development_stages_support.md) for GitLab Dedicated customers.
> - [Changed](https://gitlab.com/groups/gitlab-org/-/epics/12729) to Beta and made available on GitLab.com in GitLab 17.1.
> - [Enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/156907) in GitLab 17.2 [with flags](../../../../administration/feature_flags.md) named `pre_receive_secret_detection_beta_release` and `pre_receive_secret_detection_push_check`.
> - Feature flag `pre_receive_secret_detection_beta_release` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/472418) in GitLab 17.4.
> - [Generally available](https://gitlab.com/groups/gitlab-org/-/epics/13107) in GitLab 17.5.
> - Feature flag `pre_receive_secret_detection_push_check` [removed](https://gitlab.com/gitlab-org/gitlab/-/issues/472419) in GitLab 17.7.

Secret push protection blocks secrets such as keys and API tokens from being pushed to GitLab. The
content of each [file or commit](#coverage) is checked for secrets when pushed to GitLab. By
default, the push is blocked if a secret is found.

Use [pipeline secret detection](../_index.md) together with secret push protection to further strengthen your security.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see the playlist [Get Started with Secret Push Protection](https://www.youtube.com/playlist?list=PL05JrBw4t0KoADm-g2vxfyR0m6QLphTv-).

Regardless of the Git client, GitLab prompts a message when a push is
blocked, including details of:

- Commit ID containing the secret.
- Filename and line containing the secret.
- Type of secret.

For example, the following is an extract of the message returned when a push using the Git CLI is
blocked. When using other clients, including the GitLab Web IDE, the format of the message is
different but the content is the same.

```plain
remote: PUSH BLOCKED: Secrets detected in code changes
remote: Secret push protection found the following secrets in commit: 37e54de5e78c31d9e3c3821fd15f7069e3d375b6
remote:
remote: -- test.txt:2 GitLab Personal Access Token
remote:
remote: To push your changes you must remove the identified secrets.
```

If secret push protection does not detect any secrets in your commits, no message is displayed.

## Detected secrets

Secret push protection scans [files or commits](#coverage) for specific patterns. Each pattern
matches a specific type of secret. To confirm which secrets are detected by secret push protection,
see [Detected secrets](../detected_secrets.md). Only high-confidence patterns were chosen for secret
push protection, to minimize the delay when pushing your commits and minimize the number of false
alerts. You can [exclude](../exclusions.md) selected secrets from detection by secret push
protection.

## Enable secret push protection

On GitLab Dedicated and Self-managed instances, you must:

1. [Allow secret push protection on the entire instance](#allow-the-use-of-secret-push-protection-in-your-gitlab-instance).
1. [Enable secret push protection per project](#enable-secret-push-protection-in-a-project).

On GitLab.com, you must enable secret push protection per project.

### Allow the use of secret push protection in your GitLab instance

On GitLab Dedicated and Self-managed instances, you must allow secret push protection before you can enable it in a project.

Prerequisites:

- You must be an administrator for your GitLab instance.

To allow the use of secret push protection in your GitLab instance:

1. Sign in to your GitLab instance as an administrator.
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Security and compliance**.
1. Under **Secret detection**, select or clear **Allow secret push protection**.

Secret push protection is allowed on the instance. To use this feature, you must enable it per project.

### Enable secret push protection in a project

Prerequisites:

- You must have at least the Maintainer role for the project.
- On GitLab Dedicated and Self-managed, you must allow secret push protection on the instance.

To enable secret push protection in a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. On the left sidebar, select **Secure > Security configuration**.
1. Turn on the **Secret push protection** toggle.

You can also enable secret push protection for all projects in a group [with the API](../../../../api/group_security_settings.md#update-secret_push_protection_enabled-setting).

## Coverage

By default, secret push protection checks the content of each file modified in a commit. If you
have [diff scanning](#diff-scanning) enabled for the project, only the changes (diff) to each file
are checked for secrets. The commit is blocked from being pushed to GitLab if a secret is detected
in the commit.

Secret push protection does not block a secret when:

- You used the [skip secret push protection](#skip-secret-push-protection) option when you pushed
  the commits.
- The secret is [excluded](../exclusions.md) from secret push protection.
- The secret is in a path defined as an [exclusion](../exclusions.md).

Secret push protection does not check a file in a commit when:

- The file is a binary file.
- The file is larger than 1 MiB.
- The diff patch for the file is larger than 1 MiB (when using [diff scanning](#diff-scanning)).
- The file was renamed, deleted, or moved without changes to the content.
- The content of the file is identical to the content of another file in the source code.
- The file is contained in the initial push that created the repository.

### Diff scanning

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/469161) in GitLab 17.5 [with a flag](../../../../administration/feature_flags.md) named `spp_scan_diffs`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/480092) in GitLab 17.6.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

By default, secret push protection checks the content of each file modified in a commit. This can
cause a [push to be blocked unexpectedly](#push-blocked-unexpectedly) even though your commits don't
contain a secret. To instead have only the changes (diff) scanned for secrets when pushing by using
the Git CLI client, enable diff scanning.

Changes committed by using the Web IDE still result in the entire file being scanned due to a
technical limitation. Support for improvements is proposed in
[issue 491282](https://gitlab.com/gitlab-org/gitlab/-/issues/491282).

## Resolve a blocked push

When secret push protection blocks a push, you can either:

- [Remove the secret](#remove-the-secret)
- [Skip secret push protection](#skip-secret-push-protection)

### Remove the secret

Remove a blocked secret to allow the commit to be pushed to GitLab. The method of removing the
secret depends on how recently it was committed. The instructions below use the Git CLI client,
but you can achieve the same result by using another Git client.

If the blocked secret was added with the most recent commit on your branch:

1. Remove the secrets from the files.
1. Stage the changes with `git add <file-name>`.
1. Modify the most recent commit to include the changed files with `git commit --amend`.
1. Push your changes with `git push`.

If the blocked secret appears earlier in your Git history:

1. Optional. Watch a short demo of [removing secrets from your commits](https://www.youtube.com/watch?v=2jBC3uBUlyU).
1. Identify the commit SHA from the push error message. If there are multiple, find the earliest using `git log`.
1. Create a copy branch to work from with `git switch --create copy-branch` so you can reset to the original branch if the rebase encounters issues.
1. Use `git rebase -i <commit-sha>~1` to start an interactive rebase.
1. Mark the offending commits for editing by changing the `pick` command to `edit` in the editor.
1. Remove the secrets from the files.
1. Stage the changes with `git add <file-name>`.
1. Commit the changed files with `git commit --amend`.
1. Continue the rebase with `git rebase --continue` until all secrets are removed.
1. Push your changes from the copy branch to your original remote branch
   with `git push --force --set-upstream origin copy-branch:<original-branch>`.
1. When you are satisfied with the changes, consider the following optional cleanup steps.
   1. Optional. Delete the original branch with `git branch --delete --force <original-branch>`.
   1. Optional. Replace the original branch by renaming the copy branch with `git branch --move copy-branch <original-branch>`.

### Skip secret push protection

In some cases, it may be necessary to skip secret push protection. For example, a developer may need
to commit a placeholder secret for testing, or a user may want to skip secret push protection due to
a Git operation timeout.

[Audit events](../../../compliance/audit_event_types.md#secret-detection) are logged when
secret push protection is skipped. Audit event details include:

- Skip method used.
- GitLab account name.
- Date and time at which secret push protection was skipped.
- Name of project that the secret was pushed to.
- Target branch. (Introduced in GitLab 17.4)
- Commits that skipped secret push protection. (Introduced in GitLab 17.9)

If [pipeline secret detection](../pipeline/_index.md) is enabled, the content of all commits are
scanned after they are pushed to the repository.

To skip secret push protection for all commits in a push, either:

- If you're using the Git CLI client, [instruct Git to skip secret push protection](#skip-when-using-the-git-cli-client).
- If you're using any other client, [add `[skip secret push protection]` to one of the commit messages](#skip-when-using-the-git-cli-client).

#### Skip when using the Git CLI client

To skip secret push protection when using the Git CLI client:

- Use the [push option](../../../../topics/git/commit.md#push-options-for-secret-push-protection).

  For example, you have several commits that are blocked from being pushed because one of them
  contains a secret. To skip secret push protection, you append the push option to the Git command.

  ```shell
  git push -o secret_push_protection.skip_all
  ```

#### Skip when using any Git client

To skip secret push protection when using any Git client:

- Add `[skip secret push protection]` to one of the commit messages, on either an existing line or a new
  line, then push the commits.

  For example, you are using the GitLab Web IDE and have several commits that are blocked from being
  pushed because one of them contains a secret. To skip secret push protection, edit the latest
  commit message and add `[skip secret push protection]`, then push the commits.

## Troubleshooting

When working with secret push protection, you may encounter the following situations.

### Push blocked unexpectedly

Secret push protection scans all contents of modified files. This can cause a push to be
unexpectedly blocked if a modified file contains a secret, even if the secret is not part of the
diff.

[Enable the `spp_scan_diffs` feature flag](#diff-scanning) to ensure that only newly committed
changes are scanned. To push a Web IDE change to a file that contains a secret, you need to
[skip secret push protection](#skip-secret-push-protection).

### File was not scanned

Some files are excluded from scanning. For details see [coverage](#coverage).
