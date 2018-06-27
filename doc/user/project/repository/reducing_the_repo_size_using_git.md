# Reducing the repository size using Git

A GitLab Enterprise Edition administrator can set a [repository size limit][admin-repo-size]
which will prevent you to exceed it.

When a project has reached its size limit, you will not be able to push to it,
create a new merge request, or merge existing ones. You will still be able to
create new issues, and clone the project though. Uploading LFS objects will
also be denied.

In order to lift these restrictions, the administrator of the GitLab instance
needs to increase the limit on the particular project that exceeded it or you
need to instruct Git to rewrite changes.

If you exceed the repository size limit, your first thought might be to remove
some data, make a new commit and push back to the repository. Unfortunately,
it's not so easy and that workflow won't work. Deleting files in a commit doesn't
actually reduce the size of the repo since the earlier commits and blobs are
still around. What you need to do is rewrite history with Git's
[`filter-branch` option][gitscm].

Note that even with that method, until `git gc` runs on the GitLab side, the
"removed" commits and blobs will still be around. And if a commit was ever
included in an MR, or if a build was run for a commit, or if a user commented
on it, it will be kept around too. So, in these cases the size will not decrease.

The only fool proof way to actually decrease the repository size is to prune all
the unneeded stuff locally, and then create a new project on GitLab and start
using that instead.

With that being said, you can try reducing your repository size with the
following method.

## Using `git filter-branch` to purge files

>
**Warning:**
Make sure to first make a copy of your repository since rewriting history will
purge the files and information you are about to delete. Also make sure to
inform any collaborators to not use `pull` after your changes, but use `rebase`.

1. Navigate to your repository:

    ```
    cd my_repository/
    ```

1. Change to the branch you want to remove the big file from:

    ```
    git checkout master
    ```

1. Use `filter-branch` to remove the big file:

    ```
    git filter-branch --force --tree-filter 'rm -f path/to/big_file.mpg' HEAD
    ```

1. Instruct Git to purge the unwanted data:

    ```
    git reflog expire --expire=now --all && git gc --prune=now --aggressive
    ```

1. Lastly, force push to the repository:

    ```
    git push --force origin master
    ```

Your repository should now be below the size limit.

>**Note:**
As an alternative to `filter-branch`, you can use the `bfg` tool with a
command like: `bfg --delete-files path/to/big_file.mpg`. Read the
[BFG Repo-Cleaner][bfg] documentation for more information.

[admin-repo-size]: https://docs.gitlab.com/ee/user/admin_area/settings/account_and_limit_settings.html#repository-size-limit
[bfg]: https://rtyley.github.io/bfg-repo-cleaner/
[gitscm]: https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History#The-Nuclear-Option:-filter-branch
