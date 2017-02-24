# Account and limit settings

## Repository size limit

> [Introduced][ee-740] in GitLab Enterprise Edition 8.12.

Repositories within your GitLab instance can grow quickly, especially if you are
using LFS. Their size can grow exponentially and eat up your storage device quite
fast.

In order to avoid this from happening, you can set a hard limit for your
repositories' size. This limit can be set globally, per group, or per project,
with per project limits taking the highest priority.

Only a GitLab administrator can set those limits. Setting the limit to `0` means
there are no restrictions.

These settings can be found within each project's settings, in a group's
settings and in the Application Settings area for the global value
(`/admin/application_settings`).

The very first push of a new project cannot be checked for size as of now, so
the first push will allow you to upload more than the limit dictates, but every
subsequent push will be denied. LFS objects, however, can be checked on first
push and **will** be rejected if the sum of their sizes exceeds the maximum
allowed repository size.

For more manually purging the files, read the docs on
[reducing the repository size using Git][repo-size].

[ee-740]: https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/740
[repo-size]: ../../project/repository/reducing_the_repo_size_using_git.md
