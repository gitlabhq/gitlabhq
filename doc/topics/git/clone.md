---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Clone a Git repository to your local computer
---

When you clone a repository, a connection is created with a server and the files from the remote repository are downloaded to your computer.

This connection requires you to add credentials. You can either use SSH or HTTPS. SSH is recommended.

## Clone with SSH

Clone with SSH when you want to authenticate only one time.

1. Authenticate with GitLab by following the instructions in the [SSH documentation](../../user/ssh.md).
1. On the left sidebar, select **Search or go to** and find the project you want to clone.
1. On the project's overview page, in the upper-right corner, select **Code**, then copy the URL for **Clone with SSH**.
1. Open a terminal and go to the directory where you want to clone the files.
   Git automatically creates a folder with the repository name and downloads the files there.
1. Run this command:

   ```shell
   git clone <copied URL>
   ```

1. To view the files, go to the new directory:

   ```shell
   cd <new directory>
   ```

## Clone with HTTPS

Clone with HTTPS when you want to authenticate each time you perform an operation between your computer and GitLab.
[OAuth credential helpers](../../user/profile/account/two_factor_authentication.md#oauth-credential-helpers) can decrease
the number of times you must manually authenticate, making HTTPS a seamless experience.

1. On the left sidebar, select **Search or go to** and find the project you want to clone.
1. On the project's overview page, in the upper-right corner, select **Code**, then copy the URL for **Clone with HTTPS**.
1. Open a terminal and go to the directory where you want to clone the files.
1. Run the following command. Git automatically creates a folder with the repository name and downloads the files there.

   ```shell
   git clone <copied URL>
   ```

1. GitLab requests your username and password.

   If you have enabled two-factor authentication (2FA) on your account, you cannot use your account password. Instead, you can do one of the following:

   - [Clone using a token](#clone-using-a-token) with `read_repository` or `write_repository` permissions.
   - Install an [OAuth credential helper](../../user/profile/account/two_factor_authentication.md#oauth-credential-helpers).

   If you have not enabled 2FA, use your account password.

1. To view the files, go to the new directory:

   ```shell
   cd <new directory>
   ```

NOTE:
On Windows, if you enter your password incorrectly multiple times and an `Access denied` message appears,
add your namespace (username or group) to the path:
`git clone https://namespace@gitlab.com/gitlab-org/gitlab.git`.

### Clone using a token

Clone with HTTPS using a token if:

- You want to use 2FA.
- You want to have a revocable set of credentials scoped to one or more repositories.

You can use any of these tokens to authenticate when cloning over HTTPS:

- [Personal access tokens](../../user/profile/personal_access_tokens.md).
- [Deploy tokens](../../user/project/deploy_tokens/_index.md).
- [Project access tokens](../../user/project/settings/project_access_tokens.md).
- [Group access tokens](../../user/group/settings/group_access_tokens.md).

For example:

```shell
git clone https://<username>:<token>@gitlab.example.com/tanuki/awesome_project.git
```

## Clone and open in Apple Xcode

Projects that contain a `.xcodeproj` or `.xcworkspace` directory can be cloned
into Xcode on macOS.

1. From the GitLab UI, go to the project's overview page.
1. In the upper-right corner, select **Code**.
1. Select **Xcode**.

The project is cloned onto your computer and you are
prompted to open Xcode.

## Clone and open in Visual Studio Code

All projects can be cloned into Visual Studio Code from the GitLab user interface, but you
can also install the [GitLab Workflow extension for VS Code](../../editor_extensions/visual_studio_code/_index.md) to clone from
Visual Studio Code:

- From the GitLab interface:
  1. Go to the project's overview page.
  1. In the upper-right corner, select **Code**.
  1. Under **Open in your IDE**, select **Visual Studio Code (SSH)** or **Visual Studio Code (HTTPS)**.
  1. Select a folder to clone the project into.

     After Visual Studio Code clones your project, it opens the folder.
- From Visual Studio Code, with the [extension](../../editor_extensions/visual_studio_code/_index.md) installed, use the
  extension's [`Git: Clone` command](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#clone-gitlab-projects).

## Clone and open in IntelliJ IDEA

All projects can be cloned into [IntelliJ IDEA](https://www.jetbrains.com/idea/)
from the GitLab user interface.

Prerequisites:

- The [JetBrains Toolbox App](https://www.jetbrains.com/toolbox-app/) must be also be installed.

To do this:

1. Go to the project's overview page.
1. In the upper-right corner, select **Code**.
1. Under **Open in your IDE**, select **IntelliJ IDEA (SSH)** or **IntelliJ IDEA (HTTPS)**.

## Reduce clone size

As Git repositories grow in size, they can become cumbersome to work with
because of:

- The large amount of history that must be downloaded.
- The large amount of disk space they require.

[Partial clone](https://git-scm.com/docs/partial-clone)
is a performance optimization that allows Git to function without having a
complete copy of the repository. The goal of this work is to allow Git better
handle extremely large repositories.

Git 2.22.0 or later is required.

### Filter by file size

Storing large binary files in Git is usually discouraged, because every large
file added is downloaded by everyone who clones or fetches changes
thereafter. These downloads are slow and problematic, especially when working from a slow
or unreliable internet connection.

Using partial clone with a file size filter solves this problem, by excluding
troublesome large files from clones and fetches. When Git encounters a missing
file, it's downloaded on demand.

When cloning a repository, use the `--filter=blob:limit=<size>` argument. For example,
to clone the repository excluding files larger than 1 megabyte:

```shell
git clone --filter=blob:limit=1m git@gitlab.com:gitlab-com/www-gitlab-com.git
```

This would produce the following output:

```shell
Cloning into 'www-gitlab-com'...
remote: Enumerating objects: 832467, done.
remote: Counting objects: 100% (832467/832467), done.
remote: Compressing objects: 100% (207226/207226), done.
remote: Total 832467 (delta 585563), reused 826624 (delta 580099), pack-reused 0
Receiving objects: 100% (832467/832467), 2.34 GiB | 5.05 MiB/s, done.
Resolving deltas: 100% (585563/585563), done.
remote: Enumerating objects: 146, done.
remote: Counting objects: 100% (146/146), done.
remote: Compressing objects: 100% (138/138), done.
remote: Total 146 (delta 8), reused 144 (delta 8), pack-reused 0
Receiving objects: 100% (146/146), 471.45 MiB | 4.60 MiB/s, done.
Resolving deltas: 100% (8/8), done.
Updating files: 100% (13008/13008), done.
Filtering content: 100% (3/3), 131.24 MiB | 4.65 MiB/s, done.
```

The output is longer because Git:

1. Clones the repository excluding files larger than 1 megabyte.
1. Downloads any missing large files needed to check out the default branch.

When changing branches, Git may download more missing files.

### Filter by object type

For repositories with millions of files and a long history, you can exclude all files and use
[`git sparse-checkout`](https://git-scm.com/docs/git-sparse-checkout) to reduce the size of
your working copy.

```shell
# Clone the repo excluding all files
$ git clone --filter=blob:none --sparse git@gitlab.com:gitlab-com/www-gitlab-com.git
Cloning into 'www-gitlab-com'...
remote: Enumerating objects: 678296, done.
remote: Counting objects: 100% (678296/678296), done.
remote: Compressing objects: 100% (165915/165915), done.
remote: Total 678296 (delta 472342), reused 673292 (delta 467476), pack-reused 0
Receiving objects: 100% (678296/678296), 81.06 MiB | 5.74 MiB/s, done.
Resolving deltas: 100% (472342/472342), done.
remote: Enumerating objects: 28, done.
remote: Counting objects: 100% (28/28), done.
remote: Compressing objects: 100% (25/25), done.
remote: Total 28 (delta 0), reused 12 (delta 0), pack-reused 0
Receiving objects: 100% (28/28), 140.29 KiB | 341.00 KiB/s, done.
Updating files: 100% (28/28), done.

$ cd www-gitlab-com

$ git sparse-checkout set data --cone
remote: Enumerating objects: 301, done.
remote: Counting objects: 100% (301/301), done.
remote: Compressing objects: 100% (292/292), done.
remote: Total 301 (delta 16), reused 102 (delta 9), pack-reused 0
Receiving objects: 100% (301/301), 1.15 MiB | 608.00 KiB/s, done.
Resolving deltas: 100% (16/16), done.
Updating files: 100% (302/302), done.
```

For more details, see the Git documentation for
[`sparse-checkout`](https://git-scm.com/docs/git-sparse-checkout).

### Filter by file path

Deeper integration between partial clone and sparse checkout is possible through the
`--filter=sparse:oid=<blob-ish>` filter spec. This mode of filtering uses a format similar to a
`.gitignore` file to specify which files to include when cloning and fetching.

WARNING:
Partial clone using `sparse` filters is still experimental. It might be slow and significantly increase
[Gitaly](../../administration/gitaly/_index.md) resource utilization when cloning and fetching.
[Filter all blobs and use sparse-checkout](#filter-by-object-type) instead, because
[`git-sparse-checkout`](https://git-scm.com/docs/git-sparse-checkout) simplifies
this type of partial clone use and overcomes its limitations.

For more details, see the Git documentation for
[`rev-list-options`](https://git-scm.com/docs/git-rev-list#Documentation/git-rev-list.txt---filterltfilter-specgt).

1. Create a filter spec. For example, consider a monolithic repository with many applications,
   each in a different subdirectory in the root. Create a file `shiny-app/.filterspec`:

   ```plaintext
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

1. Clone and filter by path. Support for `--filter=sparse:oid` using the
   clone command is not fully integrated with sparse checkout.

   ```shell
   # Clone the filtered set of objects using the filterspec stored on the
   # server. WARNING: this step may be very slow!
   git clone --sparse --filter=sparse:oid=master:shiny-app/.gitfilterspec <url>

   # Optional: observe there are missing objects that we have not fetched
   git rev-list --all --quiet --objects --missing=print | wc -l
   ```

   WARNING:
   Git integrations with `bash`, Zsh, etc and editors that automatically
   show Git status information often run `git fetch` which fetches the
   entire repository. Disabling or reconfiguring these integrations might be required.

### Remove partial clone filtering

Git repositories with partial clone filtering can have the filtering removed. To
remove filtering:

1. Fetch everything that has been excluded by the filters, to make sure that the
   repository is complete. If `git sparse-checkout` was used, use
   `git sparse-checkout disable` to disable it. See the
   [`disable` documentation](https://git-scm.com/docs/git-sparse-checkout#Documentation/git-sparse-checkout.txt-emdisableem)
   for more information.

   Then do a regular `fetch` to ensure that the repository is complete. To check if
   there are missing objects to fetch, and then fetch them, especially when not using
   `git sparse-checkout`, the following commands can be used:

   ```shell
   # Show missing objects
   git rev-list --objects --all --missing=print | grep -e '^\?'

   # Show missing objects without a '?' character before them (needs GNU grep)
   git rev-list --objects --all --missing=print | grep -oP '^\?\K\w+'

   # Fetch missing objects
   git fetch origin $(git rev-list --objects --all --missing=print | grep -oP '^\?\K\w+')

   # Show number of missing objects
   git rev-list --objects --all --missing=print | grep -e '^\?' | wc -l
   ```

1. Repack everything. This can be done using `git repack -a -d`, for example. This
   should leave only three files in `.git/objects/pack/`:
   - A `pack-<SHA1>.pack` file.
   - Its corresponding `pack-<SHA1>.idx` file.
   - A `pack-<SHA1>.promisor` file.

1. Delete the `.promisor` file. The above step should have left only one
   `pack-<SHA1>.promisor` file, which should be empty and should be deleted.

1. Remove partial clone configuration. The partial clone-related configuration
   variables should be removed from Git configuration files. Usually only the following
   configuration must be removed:
   - `remote.origin.promisor`.
   - `remote.origin.partialclonefilter`.
