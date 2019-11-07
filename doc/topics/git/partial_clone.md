# Partial Clone for Large Repositories

CAUTION: **Alpha:**
Partial Clone is an experimental feature, and will significantly increase
Gitaly resource utilization when performing a partial clone, and decrease
performance of subsequent fetch operations.

As Git repositories become very large, usability decreases as performance
decreases. One major challenge is cloning the repository, because Git will
download the entire repository including every commit and every version of
every object. This can be slow to transfer, and require large amounts of disk
space.

Historically, performing a **shallow clone**
([`--depth`](https://www.git-scm.com/docs/git-clone#Documentation/git-clone.txt---depthltdepthgt))
has been the only way to reduce the amount of data transferred when cloning
a Git repository. This does not, however, allow filtering by sub-tree which is
important for monolithic repositories containing many projects, or by object
size preventing unnecessary large objects being downloaded.

[Partial clone](https://github.com/git/git/blob/master/Documentation/technical/partial-clone.txt)
is a performance optimization that "allows Git to function without having a
complete copy of the repository. The goal of this work is to allow Git better
handle extremely large repositories."

Specifically, using partial clone, it should be possible for Git to natively
support:

- large objects, instead of using [Git LFS](https://git-lfs.github.com/)
- enormous repositories

Briefly, partial clone works by:

- excluding objects from being transferred when cloning or fetching a
  repository using a new `--filter` flag
- downloading missing objects on demand

Follow [Git for enormous repositories](https://gitlab.com/groups/gitlab-org/-/epics/773) for roadmap and updates.

## Enabling partial clone

> [Introduced](https://gitlab.com/gitlab-org/gitaly/issues/1553) in GitLab 12.4.

To enable partial clone, use the [feature flags API](../../api/features.md).
For example:

```sh
curl --data "value=true" --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/features/gitaly_upload_pack_filter
```

Alternatively, flip the switch and enable the feature flag:

```ruby
Feature.enable(:gitaly_upload_pack_filter)
```

## Excluding objects by size

Partial Clone allows large objects to be stored directly in the Git repository,
and be excluded from clones as desired by the user. This eliminates the error
prone process of deciding which objects should be stored in LFS or not. Using
partial clone, all files – large or small – may be treated the same.

With the `uploadpack.allowFilter` and `uploadpack.allowAnySHA1InWant` options
enabled on the Git server:

```bash
# clone the repo, excluding blobs larger than 1 megabyte
git clone --filter=blob:limit=1m <url>

# in the checkout step of the clone, and any subsequent operations
# any blobs that are needed will be downloaded on demand
git checkout feature-branch
```

## Excluding objects by path

Partial Clone allows clones to be filtered by path using a format similar to a
`.gitignore` file stored inside the repository.

With the `uploadpack.allowFilter` and `uploadpack.allowAnySHA1InWant` options
enabled on the Git server:

1. **Create a filter spec.** For example, consider a monolithic repository with
   many applications, each in a different subdirectory in the root. Create a file
   `shiny-app/.filterspec` using the GitLab web interface:

   ```.gitignore
   # Only the paths listed in the file will be downloaded when performing a
   # partial clone using `--filter=sparse:oid=shiny-app/.gitfilterspec`

   # Explicitly include filterspec needed to configure sparse checkout with
   # git config --local core.sparsecheckout true
   # git show master:snazzy-app/.gitfilterspec >> .git/info/sparse-checkout
   shiny-app/.gitfilterspec

   # Shiny App
   shiny-app/

   # Dependencies
   shimmery-app/
   shared-component-a/
   shared-component-b/
   ```

1. *Create a new Git repository and fetch.* Support for `--filter=sparse:oid`
   using the clone command is incomplete, so we will emulate the clone command
   by hand, using `git init` and `git fetch`. Follow
   [issue tracking support for `--filter=sparse:oid`](https://gitlab.com/gitlab-org/git/issues/4)
   for updates.

   ```bash
   # Create a new directory for the Git repository
   mkdir jumbo-repo && cd jumbo-repo

   # Initialize a new Git repository
   git init

   # Add the remote
   git remote add origin <url>

   # Enable partial clone support for the remote
   git config --local extensions.partialClone origin

   # Fetch the filtered set of objects using the filterspec stored on the
   # server. WARNING: this step is slow!
   git fetch --filter=sparse:oid=master:shiny-app/.gitfilterspec origin

   # Optional: observe there are missing objects that we have not fetched
   git rev-list --all --quiet --objects --missing=print | wc -l
   ```

   CAUTION: **IDE and Shell integrations:**
   Git integrations with `bash`, `zsh`, etc and editors that automatically
   show Git status information often run `git fetch` which will fetch the
   entire repository. You many need to disable or reconfigure these
   integrations.

1. **Sparse checkout** must be enabled and configured to prevent objects from
   other paths being downloaded automatically when checking out branches. Follow
   [issue proposing automating sparse checkouts](https://gitlab.com/gitlab-org/git/issues/5) for updates.

   ```bash
   # Enable sparse checkout
   git config --local core.sparsecheckout true

   # Configure sparse checkout
   git show master:snazzy-app/.gitfilterspec >> .git/info/sparse-checkout

   # Checkout master
   git checkout master
   ```
