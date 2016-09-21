# Repository size restrictions

> Introduced with GitLab Enterprise Edition 8.12

Repositories within your GitLab instance can grow quickly, specially if you are
using LFS. Their size can grow exponentially and eat up your storage device quite
quickly.

In order to avoid this from happening, you can set a hard limit for your repositories.
You can set this limit globally, per group, or per project, with per project limits
taking the highest priority.

These settings can be found within each project, or group settings and within
the Application Settings for the global value.

Setting the limit to `0` means there is no restrictions.

# Restrictions

When a project has reached its size limit, you will not be able to push to it,
create new merge request, or merge existing ones. You will still be able to create
new issues, and clone the project.

Uploading LFS objects will also be denied.

In order to lift these restrictions, the administrator of the GitLab instance
needs to increase the limit on the particular project that exceeded it.


# Limitations

The first push of a new project cannot be checked for size as of now, so the first
push will allow you to upload more than the limit dictates, but every subsequent
push will be denied.

LFS objects, however, can be checked on first push and **will** be rejected if the
sum of their sizes exceeds the maximum allowed repository size.