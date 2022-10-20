---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Repository checks **(FREE SELF)**

You can use [`git fsck`](https://git-scm.com/docs/git-fsck) to verify the integrity of all data
committed to a repository. GitLab administrators can:

- Manually trigger this check for a project, using the GitLab UI.
- Schedule this check to run automatically for all projects.
- Run this check from the command line.
- Run a [Rake task](raketasks/check.md#repository-integrity) for checking Git repositories, which can be used to run
  `git fsck` against all repositories and generate repository checksums, as a way to compare repositories on different
  servers.

## Check a project's repository using GitLab UI

To check a project's repository using GitLab UI:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Overview > Projects**.
1. Select the project to check.
1. In the **Repository check** section, select **Trigger repository check**.

The checks run asynchronously so it may take a few minutes before the check result is visible on the
project page in the Admin Area. If the checks fail, see [what to do](#what-to-do-if-a-check-failed).

## Enable repository checks for all projects

Instead of checking repositories manually, GitLab can be configured to run the checks periodically:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Repository** (`/admin/application_settings/repository`).
1. Expand the **Repository maintenance** section.
1. Enable **Enable repository checks**.

When enabled, GitLab periodically runs a repository check on all project repositories and wiki
repositories to detect possible data corruption. A project is checked no more than once per month.
Administrators can configure the frequency of repository checks. To edit the frequency:

- For Omnibus GitLab installations, edit `gitlab_rails['repository_check_worker_cron']` in
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
[Gitaly servers](gitaly/index.md). To locate the repositories:

1. Go to the storage location for repositories:
   - For Omnibus GitLab installations, repositories are stored in the `/var/opt/gitlab/git-data/repositories` directory
     by default.
   - For GitLab Helm chart installations, repositories are stored in the `/home/git/repositories` directory inside the
     Gitaly pod by default.
1. [Identify the subdirectory that contains the repository](repository_storage_types.md#from-project-name-to-hashed-path)
   that you need to check.
1. Run the check. For example:

   ```shell
   sudo -u git /opt/gitlab/embedded/bin/git -C /var/opt/gitlab/git-data/repositories/@hashed/0b/91/0b91...f9.git fsck
   ```

## What to do if a check failed

If a repository check fails, locate the error in the [`repocheck.log` file](logs/index.md#repochecklog) on disk at:

- `/var/log/gitlab/gitlab-rails` for Omnibus GitLab installations.
- `/home/git/gitlab/log` for installations from source.
- `/var/log/gitlab` in the Sidekiq pod for GitLab Helm chart installations.

If periodic repository checks cause false alarms, you can clear all repository check states:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > Repository** (`/admin/application_settings/repository`).
1. Expand the **Repository maintenance** section.
1. Select **Clear all repository checks**.

### Error: `failed to parse commit <commit SHA> from object database for commit-graph`

You can see a `failed to parse commit <commit SHA> from object database for commit-graph` error in repository check logs. This error occurs if your `commit-graph` cache is out
of date. The `commit-graph` cache is an auxiliary cache and is not required for regular Git operations.

While the message can be safely ignored, see the issue [error: Could not read from object database for commit-graph](https://gitlab.com/gitlab-org/gitaly/-/issues/2359)
for more details.
