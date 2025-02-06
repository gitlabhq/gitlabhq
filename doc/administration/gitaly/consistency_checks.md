---
stage: Systems
group: Gitaly
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Repository consistency checks
---

Gitaly runs repository consistency checks:

- When triggering a repository check.
- When changes are fetched from a mirrored repository.
- When users push changes into repository.

These consistency checks verify that a repository has all required objects and
that these objects are valid objects. They can be categorized as:

- Basic checks that assert that a repository doesn't become corrupt. This
  includes connectivity checks and checks that objects can be parsed.
- Security checks that recognize objects that are suitable to exploit past
  security-related bugs in Git.
- Cosmetic checks that verify that all object metadata is valid. Older Git
  versions and other Git implementations may have produced objects with invalid
  metadata, but newer versions can interpret these malformed objects.

Removing malformed objects that fail the consistency checks requires a
rewrite of the repository's history, which often can't be done. Therefore,
Gitaly by default [disables consistency checks for a range of cosmetic issues](#disabled-checks)
that don't negatively impact repository consistency.

By default, Gitaly doesn't disable basic or security-related checks so
to not distribute objects that can trigger known vulnerabilities in Git
clients. This also limits the ability to import repositories containing such
objects even if the project doesn't have malicious intent.

## Override repository consistency checks

Instance administrators can override consistency checks if they must
process repositories that do not pass consistency checks.

For Linux package installations, edit `/etc/gitlab/gitlab.rb` and set the
following keys (in this example, to disable the `hasDotgit` consistency check):

- In [GitLab 15.10](https://gitlab.com/gitlab-org/gitaly/-/issues/4754) and later:

  ```ruby
  ignored_blobs = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"

  gitaly['configuration'] = {
    # ...
    git: {
      # ...
      config: [
        # Populate a file with one unabbreviated SHA-1 per line.
        # See https://git-scm.com/docs/git-config#Documentation/git-config.txt-fsckskipList
        { key: "fsck.skipList", value: ignored_blobs },
        { key: "fetch.fsck.skipList", value: ignored_blobs },
        { key: "receive.fsck.skipList", value: ignored_blobs },

        { key: "fsck.hasDotgit", value: "ignore" },
        { key: "fetch.fsck.hasDotgit", value: "ignore" },
        { key: "receive.fsck.hasDotgit", value: "ignore" },
        { key: "fsck.missingSpaceBeforeEmail", value: "ignore" },
      ],
    },
  }
  ```

- In [GitLab 15.3](https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/6800) to GitLab 15.9:

  ```ruby
  ignored_blobs = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"

  gitaly['gitconfig'] = [

   # Populate a file with one unabbreviated SHA-1 per line.
   # See https://git-scm.com/docs/git-config#Documentation/git-config.txt-fsckskipList
   { key: "fsck.skipList", value: ignored_blobs },
   { key: "fetch.fsck.skipList", value: ignored_blobs },
   { key: "receive.fsck.skipList", value: ignored_blobs },

   { key: "fsck.hasDotgit", value: "ignore" },
   { key: "fetch.fsck.hasDotgit", value: "ignore" },
   { key: "receive.fsck.hasDotgit", value: "ignore" },
   { key: "fsck.missingSpaceBeforeEmail", value: "ignore" },
  ]
  ```

- In GitLab 15.2 and earlier (legacy method):

  ```ruby
  ignored_git_errors = [
    "hasDotgit = ignore",
    "missingSpaceBeforeEmail = ignore",
  ]
  omnibus_gitconfig['system'] = {

   # Populate a file with one unabbreviated SHA-1 per line.
   # See https://git-scm.com/docs/git-config#Documentation/git-config.txt-fsckskipList
    "fsck.skipList" => ignored_blobs
    "fetch.fsck.skipList" => ignored_blobs,
    "receive.fsck.skipList" => ignored_blobs,

    "fsck" => ignored_git_errors,
    "fetch.fsck" => ignored_git_errors,
    "receive.fsck" => ignored_git_errors,
  }
  ```

For self-compiled installations, edit the Gitaly configuration (`gitaly.toml`) to do the
equivalent:

```toml
[[git.config]]
key = "fsck.hasDotgit"
value = "ignore"

[[git.config]]
key = "fetch.fsck.hasDotgit"
value = "ignore"

[[git.config]]
key = "receive.fsck.hasDotgit"
value = "ignore"

[[git.config]]
key = "fsck.missingSpaceBeforeEmail"
value = "ignore"

[[git.config]]
key = "fetch.fsck.missingSpaceBeforeEmail"
value = "ignore"

[[git.config]]
key = "receive.fsck.missingSpaceBeforeEmail"
value = "ignore"

[[git.config]]
key = "fsck.skipList"
value = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"

[[git.config]]
key = "fetch.fsck.skipList"
value = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"

[[git.config]]
key = "receive.fsck.skipList"
value = "/etc/gitlab/instance_wide_ignored_git_blobs.txt"
```

## Disabled checks

So that Gitaly can still work with repositories with certain malformed characteristics that don't impact security or
Gitaly clients, Gitaly disables a
[subset of cosmetic checks](https://gitlab.com/gitlab-org/gitaly/-/blob/79643229c351d39a7b16d90b6023ebe5f8108c16/internal/git/command_description.go#L483-524)
by default.

For the full list of consistency checks, see the [Git documentation](https://git-scm.com/docs/git-fsck#_fsck_messages).

### `badTimezone`

The `badTimezone` check is disabled because there was a bug in Git that caused users to create commits with invalid
timezones. As a result, some Git logs contain commits that do not match the specification. Because Gitaly runs `fsck`
on received `packfiles` by default, any push containing such commits would be rejected.

### `missingSpaceBeforeDate`

The `missingSpaceBeforeDate` check is disabled because `git-fsck(1)` fails when a signature does not have a space
between the mail and the date, or the date is completely missing. This could be caused by a variety of issues, including
misbehaving Git clients.

### `zeroPaddedFilemode`

The `zeroPaddedFilemode` check is disabled because older Git versions used to zero-pad some file modes. For
example, instead of a file mode of `40000`, the tree object would have encoded the file mode as `040000`.
