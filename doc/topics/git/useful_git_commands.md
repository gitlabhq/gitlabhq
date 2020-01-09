---
type: reference
---

# Useful Git commands

Here are some useful Git commands collected by the GitLab support team. You may not
need to use often, but they can can come in handy when needed.

## Remotes

### Add another URL to a remote, so both remotes get updated on each push

```sh
git remote set-url --add <remote_name> <remote_url>
```

## Staging and reverting changes

### Remove last commit and leave the changes in unstaged

```sh
git reset --soft HEAD^
```

### Unstage a certain number of commits from HEAD

To unstage 3 commits, for example, run:

```sh
git reset HEAD^3
```

### Unstage changes to a certain file from HEAD

```sh
git reset <filename>
```

### Revert a file to HEAD state and remove changes

There are two options to revert changes to a file:

- `git checkout <filename>`
- `git reset --hard <filename>`

### Undo a previous commit by creating a new replacement commit

```sh
git revert <commit-sha>
```

### Create a new message for last commit

```sh
git commit --amend
```

### Add a file to the last commit

```sh
git add <filename>
git commit --amend
```

Append `--no-edit` to the `commit` command if you do not want to edit the commit
message.

## Stashing

### Stash changes

```sh
git stash save
```

The default behavior of `stash` is to save, so you can also use just:

```sh
git stash
```

### Unstash your changes

```sh
git stash apply
```

### Discard your stashed changes

```sh
git stash drop
```

### Apply and drop your stashed changes

```sh
git stash pop
```

## Refs and Log

### Use reflog to show the log of reference changes to HEAD

```sh
git reflog
```

### Check the Git history of a file

The basic command to check the Git history of a file:

```sh
git log <file>
```

If you get this error message:

```text
fatal: ambiguous argument <file_name>: unknown revision or path not in the working tree.
Use '--' to separate paths from revisions, like this:
```

Use this to check the Git history of the file:

```sh
git log -- <file>
```

### Find the tags that contain a particular SHA

```sh
git tag --contains <sha>
```

### Check the content of each change to a file

```sh
gitk <file>
```

### Check the content of each change to a file, follows it past file renames

```sh
gitk --follow <file>
```

## Debugging

### Use a custom SSH key for a Git command

```sh
GIT_SSH_COMMAND="ssh -i ~/.ssh/gitlabadmin" git <command>
```

### Debug cloning

With SSH:

```sh
GIT_SSH_COMMAND="ssh -vvv" git clone <git@url>
```

With HTTPS:

```sh
GIT_TRACE_PACKET=1 GIT_TRACE=2 GIT_CURL_VERBOSE=1 git clone <url>
```

### Debugging with Git embedded traces

Git includes a complete set of [traces for debugging Git commands](https://git-scm.com/book/en/v2/Git-Internals-Environment-Variables#_debugging), for example:

- `GIT_TRACE_PERFORMANCE=1`: enables tracing of performance data, showing how long each particular `git` invocation takes.
- `GIT_TRACE_SETUP=1`: enables tracing of what `git` is discovering about the repository and environment it’s interacting with.
- `GIT_TRACE_PACKET=1`: enables packet-level tracing for network operations.

## Rebasing

### Rebase your branch onto master

The -i flag stands for 'interactive':

```sh
git rebase -i master
```

### Continue the rebase if paused

```sh
git rebase --continue
```

### Use `git rerere`

To _reuse_ recorded solutions to the same problems when repeated:

```sh
git rerere
```

To enable `rerere` functionality:

```sh
git config --global rerere.enabled true
```

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
