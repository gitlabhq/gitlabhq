# Housekeeping

> [Introduced][ce-2371] in GitLab 8.4.

---
## Automatic housekeeping

GitLab automatically runs `git gc` and `git repack` on repositories
after Git pushes. If needed you can change how often this happens, or
to turn it off, go to **Admin area > Settings**
(`/admin/application_settings`).

## Manual housekeeping

The housekeeping function runs `git gc` ([man page][man]) on the current
project Git repository.

`git gc` runs a number of housekeeping tasks, such as compressing file
revisions (to reduce disk space and increase performance) and removing
unreachable objects which may have been created from prior invocations of
`git add`.

You can find this option under your **[Project] > Edit Project**.

---

![Housekeeping settings](img/housekeeping_settings.png)

[ce-2371]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/2371 "Housekeeping merge request"
[man]: https://www.kernel.org/pub/software/scm/git/docs/git-gc.html "git gc man page"
