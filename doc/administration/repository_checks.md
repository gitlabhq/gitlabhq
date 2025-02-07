---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Repository checks
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can use [`git fsck`](https://git-scm.com/docs/git-fsck) to verify the integrity of all data
committed to a repository. GitLab administrators can:

- [Manually trigger this check for a project](#check-a-projects-repository-using-gitlab-ui).
- [Schedule this check](#enable-repository-checks-for-all-projects) to run automatically for all projects.
- [Run this check from the command line](#run-a-check-using-the-command-line).
- Run a [Rake task](raketasks/check.md#repository-integrity) for checking Git repositories, which can be used to run
  `git fsck` against all repositories and generate repository checksums, as a way to compare repositories on different
  servers.

Checks that aren't manually run on the command line are executed through a Gitaly node. For information on Gitaly
repository consistency checks, some disabled checks, and how to configure consistency checks, see
[Repository consistency checks](gitaly/consistency_checks.md).

## Check a project's repository using GitLab UI

To check a project's repository using GitLab UI:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Projects**.
1. Select the project to check.
1. In the **Repository check** section, select **Trigger repository check**.

The checks run asynchronously so it may take a few minutes before the check result is visible on the
project page in the **Admin** area. If the checks fail, see [what to do](#what-to-do-if-a-check-failed).

## Enable repository checks for all projects

Instead of checking repositories manually, GitLab can be configured to run the checks periodically:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Repository**.
1. Expand **Repository maintenance**.
1. Enable **Enable repository checks**.

When enabled, GitLab periodically runs a repository check on all project repositories and wiki
repositories to detect possible data corruption. A project is checked no more than once per month, and new projects aren't checked for at least 24 hours.

Administrators can configure the frequency of repository checks. To edit the frequency:

- For Linux package installations, edit `gitlab_rails['repository_check_worker_cron']` in
  `/etc/gitlab/gitlab.rb`.
- For source-based installations, edit `[gitlab.cron_jobs.repository_check_worker]` in
  `/home/git/gitlab/config/gitlab.yml`.

If any projects fail their repository checks, all GitLab administrators receive an email
notification of the situation. By default, this notification is sent out once a week at midnight at
the start of Sunday.

Repositories with known check failures can be found at
`/admin/projects?last_repository_check_failed=1`.

## Run a check using the command line

You can run [`git fsck`](https://git-scm.com/docs/git-fsck) using the command line on repositories on
[Gitaly servers](gitaly/_index.md). To locate the repositories:

1. Go to the storage location for repositories:
   - For Linux package installations, repositories are stored in the `/var/opt/gitlab/git-data/repositories` directory
     by default.
   - For GitLab Helm chart installations, repositories are stored in the `/home/git/repositories` directory inside the
     Gitaly pod by default.
1. [Identify the subdirectory that contains the repository](repository_storage_paths.md#from-project-name-to-hashed-path)
   that you need to check.
1. Run the check. For example:

   ```shell
   sudo -u git /opt/gitlab/embedded/bin/git \
      -C /var/opt/gitlab/git-data/repositories/@hashed/0b/91/0b91...f9.git fsck --no-dangling
   ```

   The error `fatal: detected dubious ownership in repository` means you're running the command
   using the wrong account. For example, `root`.

## What to do if a check failed

If a repository check fails, locate the error in the [`repocheck.log` file](logs/_index.md#repochecklog) on disk at:

- `/var/log/gitlab/gitlab-rails` for Linux package installations.
- `/home/git/gitlab/log` for self-compiled installations.
- `/var/log/gitlab` in the Sidekiq pod for GitLab Helm chart installations.

If periodic repository checks cause false alarms, you can clear all repository check states:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Repository**.
1. Expand **Repository maintenance**.
1. Select **Clear all repository checks**.

## Troubleshooting

When working with repository checks, you might encounter the following issues.

### Error: `failed to parse commit <commit SHA> from object database for commit-graph`

You can see a `failed to parse commit <commit SHA> from object database for commit-graph` error in repository check logs. This error occurs if your `commit-graph` cache is out
of date. The `commit-graph` cache is an auxiliary cache and is not required for regular Git operations.

While the message can be safely ignored, see the issue [error: Could not read from object database for commit-graph](https://gitlab.com/gitlab-org/gitaly/-/issues/2359)
for more details.

### Dangling commit, tag, or blob messages

Repository check output often includes tags, blobs, and commits that must be pruned:

```plaintext
dangling tag 5c6886c774b713a43158aae35c4effdb03a3ceca
dangling blob 3e268c23fcd736db92e89b31d9f267dd4a50ac4b
dangling commit 919ff61d8d78c2e3ea9a32701dff70ecbefdd1d7
```

This is common in Git repositories. They're generated by operations like
force pushing to branches, because this generates a commit in the repository
that is not longer referred to by a ref or by another commit.

If a repository check fails, the output is likely to include these warnings.

Ignore these messages, and identify the root cause of the repository check failure
from the other output.

[GitLab 15.8 and later](https://gitlab.com/gitlab-org/gitaly/-/merge_requests/5230) no
longer includes these messages in the check output. Use the `--no-dangling` option
to suppress then when run from the command line.
