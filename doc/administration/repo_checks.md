# Repo checks

_**Note:** This feature was [introduced][ce-3232] in GitLab 8.7_

---

Git has a built-in mechanism [git fsck][git-fsck] to verify the
integrity of all data commited to a repository. GitLab administrators can
trigger such a check for a project via the admin panel. The checks run
asynchronously so it may take a few minutes before the check result is
visible on the project admin page. If the checks failed you can see their
output on the admin log page under 'repocheck.log'.

## Periodical checks

GitLab periodically runs a repo check on all project repositories and
wiki repositories in order to detect data corruption problems. A
project will be checked no more than once per week. If any projects
fail their repo checks all GitLab administrators will receive an email
notification of the situation. This notification is sent out no more
than once a day.


## What to do if a check failed

If the repo check fails for some repository you shouldlook up the error
in repocheck.log (in the admin panel or on disk; see
`/var/log/gitlab/gitlab-rails` for Omnibus installations or
`/home/git/gitlab/log` for installations from source). Once you have
resolved the issue use the admin panel to trigger a new repo check on
the project. This will clear the 'check failed' state.

If for some reason the periodical repo check caused a lot of false
alarms you can choose to clear ALL repo check states from the admin
project index page.

---
[ce-3232]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/3232 "Auto git fsck"
[git-fsck]: https://www.kernel.org/pub/software/scm/git/docs/git-fsck.html "git fsck documentation"