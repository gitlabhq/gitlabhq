---
type: reference
---

# Account and limit settings

## Repository size limit **[STARTER]**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/740) in [GitLab Enterprise Edition 8.12](https://about.gitlab.com/2016/09/22/gitlab-8-12-released/#limit-project-size-ee).
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
1. Although you have enabled [Git LFS](../../../workflow/lfs/manage_large_binaries_with_git_lfs.md#git-lfs)
   to your project, your storage has grown significantly.
1. Before you exceed available storage, you set up a limit of 10 GB
   per repository.

### How it works

Only a GitLab administrator can set those limits. Setting the limit to `0` means
there are no restrictions.

These settings can be found within:

- Each project's settings.
- A group's settings.
- The **Size limit per repository (MB)** field in the **Account and limit** section of a GitLab instance's
  settings by navigating to either:
  - **Admin Area > Settings > General**.
  - The path `/admin/application_settings`.

The first push of a new project, including LFS objects, will be checked for size
and **will** be rejected if the sum of their sizes exceeds the maximum allowed 
repository size.

For details on manually purging files, see [reducing the repository size using Git](../../project/repository/reducing_the_repo_size_using_git.md).

NOTE: **Note:**
For GitLab.com, the repository size limit is 10 GB.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
