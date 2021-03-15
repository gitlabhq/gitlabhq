---
stage: Create
group: Gitaly
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference
---

# Repository checks **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/3232) in GitLab 8.7.

Git has a built-in mechanism, [`git fsck`](https://git-scm.com/docs/git-fsck), to verify the
integrity of all data committed to a repository. GitLab administrators
can trigger such a check for a project via the project page under the
Admin Area. The checks run asynchronously so it may take a few minutes
before the check result is visible on the project Admin Area. If the
checks failed you can see their output on in the
[`repocheck.log` file.](logs.md#repochecklog)

This setting is off by default, because it can cause many false alarms.

## Periodic checks

When enabled, GitLab periodically runs a repository check on all project
repositories and wiki repositories in order to detect data corruption.
A project is checked no more than once per month. If any projects
fail their repository checks all GitLab administrators receive an email
notification of the situation. This notification is sent out once a week,
by default, midnight at the start of Sunday. Repositories with known check
failures can be found at `/admin/projects?last_repository_check_failed=1`.

## Disabling periodic checks

You can disable the periodic checks on the **Settings** page of the Admin Area.

## What to do if a check failed

If the repository check fails for some repository you should look up the error
in the [`repocheck.log` file](logs.md#repochecklog) on disk:

- `/var/log/gitlab/gitlab-rails` for Omnibus GitLab installations
- `/home/git/gitlab/log` for installations from source

If the periodic repository check causes false alarms, you can clear all repository check states by
going to **Admin Area > Settings > Repository**
(`/admin/application_settings/repository`) and clicking **Clear all repository checks**.

## Run a check manually

[`git fsck`](https://git-scm.com/docs/git-fsck) is a read-only check that you can run
manually against the repository on the [Gitaly server](gitaly/index.md).

- For Omnibus GitLab installations, repositories are stored by default in
  `/var/opt/gitlab/git-data/repositories`.
- [Identify the subdirectory that contains the repository](repository_storage_types.md#from-project-name-to-hashed-path)
   that you need to check.

To run a check (for example):

```shell
sudo /opt/gitlab/embedded/bin/git -C /var/opt/gitlab/git-data/repositories/@hashed/0b/91/0b91...f9.git fsck
```

You can also run [Rake tasks](raketasks/check.md#repository-integrity) for checking Git
repositories, which can be used to run `git fsck` against all repositories and generate
repository checksums, as a way to compare repositories on different servers.
