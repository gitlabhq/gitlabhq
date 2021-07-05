---
stage: Create
group: Gitaly
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
---

# Repository checks **(FREE SELF)**

You can use [`git fsck`](https://git-scm.com/docs/git-fsck) to verify the integrity of all data
committed to a repository. GitLab administrators can trigger this check for a project using the
GitLab UI:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Overview > Projects**.
1. Select the project to check.
1. In the **Repository check** section, select **Trigger repository check**.

The checks run asynchronously so it may take a few minutes before the check result is visible on the
project page in the Admin Area. If the checks fail, see [what to do](#what-to-do-if-a-check-failed).

This setting is off by default, because it can cause many false alarms.

## Enable periodic checks

Instead of checking repositories manually, GitLab can be configured to run the checks periodically:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Settings > Repository** (`/admin/application_settings/repository`).
1. Expand the **Repository maintenance** section.
1. Enable **Enable repository checks**.

When enabled, GitLab periodically runs a repository check on all project repositories and wiki
repositories to detect possible data corruption. A project is checked no more than once per month.

If any projects fail their repository checks, all GitLab administrators receive an email
notification of the situation. By default, this notification is sent out once a week at midnight at
the start of Sunday.

Repositories with known check failures can be found at
`/admin/projects?last_repository_check_failed=1`.

## What to do if a check failed

If a repository check fails, locate the error in the [`repocheck.log` file](logs.md#repochecklog) on
disk at:

- `/var/log/gitlab/gitlab-rails` for Omnibus GitLab installations.
- `/home/git/gitlab/log` for installations from source.

If periodic repository checks cause false alarms, you can clear all repository check states:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Settings > Repository** (`/admin/application_settings/repository`).
1. Expand the **Repository maintenance** section.
1. Select **Clear all repository checks**.

## Run a check using the command line

You can run [`git fsck`](https://git-scm.com/docs/git-fsck) using the command line on repositories
on [Gitaly servers](gitaly/index.md). To locate the repositories:

1. Go to the storage location for repositories. For Omnibus GitLab installations, repositories are
   stored by default in the `/var/opt/gitlab/git-data/repositories` directory.
1. [Identify the subdirectory that contains the repository](repository_storage_types.md#from-project-name-to-hashed-path)
   that you need to check.

To run a check (for example):

```shell
sudo /opt/gitlab/embedded/bin/git -C /var/opt/gitlab/git-data/repositories/@hashed/0b/91/0b91...f9.git fsck
```

You can also run [Rake tasks](raketasks/check.md#repository-integrity) for checking Git
repositories, which can be used to run `git fsck` against all repositories and generate repository
checksums, as a way to compare repositories on different servers.
