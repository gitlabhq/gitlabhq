# Housekeeping

> [Introduced][ce-2371] in GitLab 8.4.

## Automatic housekeeping

GitLab automatically runs `git gc` and `git repack` on repositories
after Git pushes. If needed you can change how often this happens, or
to turn it off, go to **Admin area > Settings**
(`/admin/application_settings`).

## Manual housekeeping

The housekeeping function will run a `repack` or `gc` depending on the
"Automatic Git repository housekeeping" settings configured in **Admin area > Settings**

For example in the following scenario a `git repack -d` will be executed:

- Project: pushes since gc counter (`pushes_since_gc`) = `10`
- Git GC period = `200`
- Full repack period = `50`

When the `pushes_since_gc` value is 50 a `repack -A -d --pack-kept-objects` will run, similarly when
the `pushes_since_gc` value is 200 a `git gc` will be run.

- `git gc` ([man page][man-gc]) runs a number of housekeeping tasks,
  such as compressing filerevisions (to reduce disk space and increase performance)
  and removing unreachable objects which may have been created from prior invocations of
  `git add`.
- `git repack` ([man page][man-repack]) re-organize existing packs into a single, more efficient pack.

You can find this option under your project's **Settings > General > Advanced**.

![Housekeeping settings](img/housekeeping_settings.png)

[ce-2371]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/2371 "Housekeeping merge request"
[man-gc]: https://www.kernel.org/pub/software/scm/git/docs/git-gc.html "git gc man page"
[man-repack]: https://www.kernel.org/pub/software/scm/git/docs/git-repack.html
