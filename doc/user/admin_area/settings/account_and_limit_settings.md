---
type: reference
---

# Account and limit settings **(CORE ONLY)**

## Max attachment size

You can change the maximum file size for attachments in comments and replies in GitLab.
Navigate to **Admin Area (wrench icon) > Settings > General**, then expand **Account and Limit**.
From here, you can increase or decrease by changing the value in `Maximum attachment size (MB)`.

NOTE: **Note:**
If you choose a size larger than what is currently configured for the web server,
you will likely get errors. See the [troubleshooting section](#troubleshooting) for more
details.

## Repository size limit **(STARTER)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/740) in [GitLab Enterprise Edition 8.12](https://about.gitlab.com/blog/2016/09/22/gitlab-8-12-released/#limit-project-size-ee).
> Available in [GitLab Starter](https://about.gitlab.com/pricing/).

Repositories within your GitLab instance can grow quickly, especially if you are
using LFS. Their size can grow exponentially, rapidly consuming available storage.

To avoid this from happening, you can set a hard limit for your repositories' size.
This limit can be set globally, per group, or per project, with per project limits
taking the highest priority.

There are numerous use cases where you might set up a limit for repository size.
For instance, consider the following workflow:

1. Your team develops apps which require large files to be stored in
   the application repository.
1. Although you have enabled [Git LFS](../../../administration/lfs/manage_large_binaries_with_git_lfs.md#git-lfs)
   to your project, your storage has grown significantly.
1. Before you exceed available storage, you set up a limit of 10 GB
   per repository.

### How it works

Only a GitLab administrator can set those limits. Setting the limit to `0` means
there are no restrictions.

These settings can be found within:

- Each project's settings:
  1. From the Project's homepage, navigate to **Settings > General**.
  1. Fill in the **Repository size limit (MB)** field in the **Naming, topics, avatar** section.
  1. Click **Save changes**.
- Each group's settings:
  1. From the Group's homepage, navigate to **Settings > General**.
  1. Fill in the **Repository size limit (MB)** field in the **Naming, visibility** section.
  1. Click **Save changes**.
- GitLab's global settings:
  1. From the Dashboard, navigate to **Admin Area > Settings > General**.
  1. Expand the **Account and limit** section.
  1. Fill in the **Size limit per repository (MB)** field.
  1. Click **Save changes**.

The first push of a new project, including LFS objects, will be checked for size
and **will** be rejected if the sum of their sizes exceeds the maximum allowed
repository size.

**Note:** The repository size limit includes repository files and LFS, and does not include artifacts.

For details on manually purging files, see [reducing the repository size using Git](../../project/repository/reducing_the_repo_size_using_git.md).

NOTE: **Note:**
GitLab.com repository size [is set by GitLab](../../gitlab_com/index.md#repository-size-limit).

## Troubleshooting

### 413 Request Entity Too Large

If you are attaching a file to a comment or reply in GitLab and receive the `413 Request Entity Too Large`
error, it is likely caused by having a [max attachment size](#max-attachment-size)
larger than what the web server is configured to allow.

If you wanted to increase the max attachment size to 200m in a GitLab
[Omnibus](https://docs.gitlab.com/omnibus/) install, for example, you might need to
add the line below to `/etc/gitlab/gitlab.rb` before increasing the max attachment size:

```
nginx['client_max_body_size'] = "200m"
```

## Limiting lifetime of personal access tokens **(ULTIMATE ONLY)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/3649) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.6.

Users can optionally specify an expiration date for
[personal access tokens](../../profile/personal_access_tokens.md).
This expiration date is not a requirement, and can be set to any arbitrary date.

Since personal access tokens are the only token needed for programmatic access to GitLab,
organizations with security requirements may want to enforce more protection to require
regular rotation of these tokens.

### Setting a limit

Only a GitLab administrator can set a limit. Leaving it empty means
there are no restrictions.

To set a limit on how long personal access tokens are valid:

1. Navigate to **Admin Area > Settings > General**.
1. Expand the **Account and limit** section.
1. Fill in the **Maximum allowable lifetime for personal access tokens (days)** field.
1. Click **Save changes**.

Once a lifetime for personal access tokens is set, GitLab will:

- Apply the lifetime for new personal access tokens, and require users to set an expiration date
  and a date no later than the allowed lifetime.
- After three hours, revoke old tokens with no expiration date or with a lifetime longer than the
  allowed lifetime. Three hours is given to allow administrators to change the allowed lifetime,
  or remove it, before revocation takes place.

## Disabling user profile name changes **(CORE ONLY)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/24605) in GitLab 12.7.

To maintain integrity of user details in [Audit Events](../../../administration/audit_events.md), GitLab administrators can choose to disable a user's ability to change their profile name.

To do this:

1. Navigate to **Admin Area > Settings > General**, then expand **Account and Limit**.
1. Check the **Prevent users from changing their profile name** checkbox.

NOTE: **Note:**
When this ability is disabled, GitLab administrators will still be able to update the name of any user in their instance via the [Admin UI](../index.md#administering-users) or the [API](../../../api/users.md#user-modification)
