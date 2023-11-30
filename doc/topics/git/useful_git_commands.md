---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
type: reference
---

# Frequently used Git commands **(FREE ALL)**

The following commands are frequently used.

## Remotes

### Add another URL to a remote, so both remotes get updated on each push

```shell
git remote set-url --add <remote_name> <remote_url>
```

### Revert a file to HEAD state and remove changes

To revert changes to a file, you can use either:

- `git checkout <filename>`
- `git reset --hard <filename>`

### Undo a previous commit by creating a new replacement commit

```shell
git revert <commit-sha>
```

### Create a new message for last commit

```shell
git commit --amend
```

### Create a new message for older commits

WARNING:
Changing commit history can disrupt others' work if they have cloned, forked, or have active branches.
Only amend pushed commits if you're sure it's safe.
To learn more, see [Git rebase and force push](git_rebase.md).

```shell
git rebase -i HEAD~n
```

Replace `n` with the number of commits you want to go back.

This opens your text editor with a list of commits.
In the editor, replace `pick` with `reword` for each commit you want to change the message:

```shell
reword 1fc6c95 original commit message
pick 6b2481b another commit message
pick 5c1291b another commit message
```

After saving and closing the file, you can update each message in a new editor window.

After updating your commits, you must push them to the repository.
As this rewrites history, a force push is required.
To prevent unintentional overwrites, use `--force-with-lease`:

```shell
git push --force-with-lease
```

### Add a file to the last commit

```shell
git add <filename>
git commit --amend
```

Append `--no-edit` to the `commit` command if you do not want to edit the commit
message.

## Refs and Log

### Use reflog to show the log of reference changes to HEAD

```shell
git reflog
```

### Check the Git history of a file

The basic command to check the Git history of a file:

```shell
git log <file>
```

If you get this error message:

```plaintext
fatal: ambiguous argument <file_name>: unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
```

Use this to check the Git history of the file:

```shell
git log -- <file>
```

### Check the content of each change to a file

```shell
gitk <file>
```

### Check the content of each change to a file, follows it past file renames

```shell
gitk --follow <file>
```

## Debugging

### Use a custom SSH key for a Git command

```shell
GIT_SSH_COMMAND="ssh -i ~/.ssh/gitlabadmin" git <command>
```

### Debug cloning

With SSH:

```shell
GIT_SSH_COMMAND="ssh -vvv" git clone <git@url>
```

With HTTPS:

```shell
GIT_TRACE_PACKET=1 GIT_TRACE=2 GIT_CURL_VERBOSE=1 git clone <url>
```

### Debugging with Git embedded traces

Git includes a complete set of [traces for debugging Git commands](https://git-scm.com/book/en/v2/Git-Internals-Environment-Variables#_debugging), for example:

- `GIT_TRACE_PERFORMANCE=1`: enables tracing of performance data, showing how long each particular `git` invocation takes.
- `GIT_TRACE_SETUP=1`: enables tracing of what `git` is discovering about the repository and environment it's interacting with.
- `GIT_TRACE_PACKET=1`: enables packet-level tracing for network operations.

## Rebasing

### Rebase your branch onto the default

The `-i` flag stands for 'interactive'. Replace `<default-branch>` with the name
of your [default branch](../../user/project/repository/branches/default.md):

```shell
git rebase -i <default-branch>
```

### Continue the rebase if paused

```shell
git rebase --continue
```

### Use `git rerere`

To _reuse_ recorded solutions to the same problems when repeated:

```shell
git rerere
```

To enable `rerere` functionality:

```shell
git config --global rerere.enabled true
```

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->