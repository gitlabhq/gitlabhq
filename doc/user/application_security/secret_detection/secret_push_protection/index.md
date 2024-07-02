---
stage: Secure
group: Secret Detection
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Secret push protection

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Dedicated
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11439) in GitLab 16.7 as an [experiment](../../../../policy/experiment-beta-support.md) for GitLab Dedicated customers.
> - [Changed](https://gitlab.com/groups/gitlab-org/-/epics/12729) to Beta and made available on GitLab.com in GitLab 17.1.

Secret push protection blocks secrets such as keys and API tokens from being pushed to GitLab.
The content of each commit is checked for secrets when pushed to GitLab. If any secrets are
detected, the push is blocked.

Secret push protection is available on GitLab.com and GitLab Dedicated. To scan for secrets
in your GitLab self-managed instance, use [pipeline secret detection](../index.md)
instead. Pipeline secret detection can be used together with secret push protection to
further secure your GitLab.com or Dedicated instance.

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

## Enable secret push protection

On GitLab Dedicated and GitLab.com, secret push protection must be enabled at the instance level and then you must enable it per project.

### Allow the use of secret push protection in your GitLab instance

NOTE:
Setting this option gives permission for projects in your GitLab instance to turn on secret push protection.
To use secret push protection, you must also enable it in each project. For details,
see [enable secret push protection in a project](#enable-secret-push-protection-in-a-project).

Prerequisites:

- You must be an administrator for your GitLab instance.

1. Sign in to your GitLab instance as an administrator.
1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > Security and Compliance**.
1. Under **Secret Detection**, select or clear **Allow secret push protection**.

### Enable secret push protection in a project

Prerequisites:

- You must have at least the Maintainer role for the project.

To enable secret push protection in a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. On the left sidebar, select **Secure > Security configuration**.
1. Turn on the **Secret push protection** toggle.

## Coverage

Secret push protection checks the content of each commit when it is pushed to GitLab.
However, the following exclusions apply.

Secret push protection does not check a file in a commit when:

- The file is a binary file.
- The file is larger than 1 MiB.
- The file was renamed, deleted, or moved without changes to the content.
- The content of the file is identical to the content of another file in the source code.
- The file is contained in the initial push that created the repository.

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

1. Identify the commit SHA from the push error message. If there are multiple, find the earliest using `git log`.
1. Use `git rebase -i <commit-sha>~1` to start an interactive rebase.
1. Mark the offending commits for editing by changing the `pick` command to `edit` in the editor.
1. Remove the secrets from the files.
1. Stage the changes with `git add <file-name>`.
1. Commit the changed files with `git commit --amend`.
1. Continue the rebase with `git rebase --continue` until all secrets are removed.
1. Push your changes with `git push`.

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

If [pipeline secret detection](../pipeline/index.md) is enabled, the content of all commits are
scanned after they are pushed to the repository.

To skip secret push protection for all commits in a push, either:

- If you're using the Git CLI client, [instruct Git to skip secret push protection](#skip-when-using-the-git-cli-client).
- If you're using any other client, [add `[skip secret detection]` to one of the commit messages](#skip-when-using-the-git-cli-client).

#### Skip when using the Git CLI client

To skip secret push protection when using the Git CLI client:

- Use the [push option](../../../../gitlab-basics/add-file.md#push-options-for-secret-push-protection).

  For example, you have several commits that are blocked from being pushed because one of them
  contains a secret. To skip secret push protection, you append the push option to the Git command.

  ```shell
  git push -o secret_detection.skip_all
  ```

#### Skip when using any Git client

To skip secret push protection when using any Git client:

- Add `[skip secret detection]` to one of the commit messages, on either an existing line or a new
  line, then push the commits.

  For example, you are using the GitLab Web IDE and have several commits that are blocked from being
  pushed because one of them contains a secret. To skip secret push protection, edit the latest
  commit message and add `[skip secret detection]`, then push the commits.
