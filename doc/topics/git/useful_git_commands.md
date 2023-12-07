---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Frequently used Git commands **(FREE ALL)**

The following commands are frequently used.

## Add another URL to a remote

Add another URL to a remote, so both remotes get updated on each push:

```shell
git remote set-url --add <remote_name> <remote_url>
```

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
