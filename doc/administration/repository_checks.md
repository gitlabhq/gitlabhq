# Repository checks

> [Introduced][ce-3232] in GitLab 8.7. It is OFF by default because it still
causes too many false alarms.

Git has a built-in mechanism, [git fsck][git-fsck], to verify the
integrity of all data committed to a repository. GitLab administrators
can trigger such a check for a project via the project page under the
admin panel. The checks run asynchronously so it may take a few minutes
before the check result is visible on the project admin page. If the
checks failed you can see their output on the admin log page under
'repocheck.log'.

## Periodic checks

GitLab periodically runs a repository check on all project repositories and
wiki repositories in order to detect data corruption problems. A
project will be checked no more than once per week. If any projects
fail their repository checks all GitLab administrators will receive an email
notification of the situation. This notification is sent out no more
than once a day.

## Disabling periodic checks

You can disable the periodic checks on the 'Settings' page of the admin
panel.

## What to do if a check failed

If the repository check fails for some repository you should look up the error
in repocheck.log (in the admin panel or on disk; see
`/var/log/gitlab/gitlab-rails` for Omnibus installations or
`/home/git/gitlab/log` for installations from source). Once you have
resolved the issue use the admin panel to trigger a new repository check on
the project. This will clear the 'check failed' state.

If for some reason the periodic repository check caused a lot of false
alarms you can choose to clear ALL repository check states from the
'Settings' page of the admin panel.

---
[ce-3232]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/3232 "Auto git fsck"
[git-fsck]: https://www.kernel.org/pub/software/scm/git/docs/git-fsck.html "git fsck documentation"
