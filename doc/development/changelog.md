# Generate a changelog entry

This guide contains instructions for generating a changelog entry data file, as
well as information and history about our changelog process.

## Overview

Each bullet point, or **entry**, in our [`CHANGELOG.md`][changelog.md] file is
generated from a single data file in the [`changelogs/unreleased/`][unreleased]
(or corresponding EE) folder. The file is expected to be a [YAML] file in the
following format:

```yaml
---
title: "Going through change[log]s"
merge_request: 1972
author: Ozzy Osbourne
```

The `merge_request` value is a reference to a merge request that adds this
entry, and the `author` key is used to give attribution to community
contributors. Both are optional.

If you're working on the GitLab EE repository, the entry will be added to
`changelogs/unreleased-ee/` instead.

[changelog.md]: https://gitlab.com/gitlab-org/gitlab-ce/blob/master/CHANGELOG.md
[unreleased]: https://gitlab.com/gitlab-org/gitlab-ce/tree/master/changelogs/
[YAML]: https://en.wikipedia.org/wiki/YAML

## Instructions

A `bin/changelog` script is available to generate the changelog entry file
automatically.

Its simplest usage is to provide the value for `title`:

```text
$ bin/changelog 'Hey DZ, I added a feature to GitLab!'
create changelogs/unreleased/my-feature.yml
---
title: Hey DZ, I added a feature to GitLab!
merge_request:
author:
```

The entry filename is based on the name of the current Git branch. If you run
the command above on a branch called `feature/hey-dz`, it will generate a
`changelogs/unreleased/feature-hey-dz` file.

### Arguments

| Argument          | Shorthand | Purpose                                       |
| ----------------- | --------- | --------------------------------------------- |
| `--amend`         |           | Amend the previous commit                     |
| `--merge-request` | `-m`      | Merge Request ID                              |
| `--dry-run`       | `-n`      | Don't actually write anything, just print     |
| `--git-username`  | `-u`      | Use Git user.name configuration as the author |
| `--help`          | `-h`      | Print help message                            |

#### `--amend`

You can pass the **`--amend`** argument to automatically stage the generated
file and amend it to the previous commit.

If you use **`--amend`** and don't provide a title, it will automatically use
the "subject" of the previous commit, which is the first line of the commit
message:

```text
$ git show --oneline
ab88683 Added an awesome new feature to GitLab

$ bin/changelog --amend
create changelogs/unreleased/feature-hey-dz.yml
---
title: Added an awesome new feature to GitLab
merge_request:
author:
```

#### `--merge-request` or `-m`

Use the **`--merge-request`** or **`-m`** argument to provide the
`merge_request` value:

```text
$ bin/changelog 'Hey DZ, I added a feature to GitLab!' -m 1983
create changelogs/unreleased/feature-hey-dz.yml
---
title: Hey DZ, I added a feature to GitLab!
merge_request: 1983
author:
```

#### `--dry-run` or `-n`

Use the **`--dry-run`** or **`-n`** argument to prevent actually writing or
committing anything:

```text
$ bin/changelog --amend --dry-run
create changelogs/unreleased/feature-hey-dz.yml
---
title: Added an awesome new feature to GitLab
merge_request:
author:

$ ls changelogs/unreleased/
```

#### `--git-username` or `-u`

Use the **`--git-username`** or **`-u`** argument to automatically fill in the
`author` value with your configured Git `user.name` value:

```text
$ git config user.name
Jane Doe

$ bin/changelog --u 'Hey DZ, I added a feature to GitLab!'
create changelogs/unreleased/feature-hey-dz.yml
---
title: Hey DZ, I added a feature to GitLab!
merge_request:
author: Jane Doe
```

## History and Reasoning

Our `CHANGELOG` file was previously updated manually by each contributor that
felt their change warranted an entry. When two merge requests added their own
entries at the same spot in the list, it created a merge conflict in one as soon
as the other was merged. When we had dozens of merge requests fighting for the
same changelog entry location, this quickly became a major source of merge
conflicts and delays in development.

This led us to a [boring solution] of "add your entry in a random location in
the list." This actually worked pretty well as we got further along in each
monthly release cycle, but at the start of a new cycle, when a new version
section was added and there were fewer places to "randomly" add an entry, the
conflicts became a problem again until we had a sufficient number of entries.

On top of all this, it created an entirely different headache for [release managers]
when they cherry-picked a commit into a stable branch for a patch release. If
the commit included an entry in the `CHANGELOG`, it would include the entire
changelog for the latest version in `master`, so the release manager would have
to manually remove the later entries. They often would have had to do this
multiple times per patch release. This was compounded when we had to release
multiple patches at once due to a security issue.

We needed to automate all of this manual work. So we [started brainstorming].
After much discussion we settled on the current solution of one file per entry,
and then compiling the entries into the overall `CHANGELOG.md` file during the
[release process].

[boring solution]: https://about.gitlab.com/handbook/#boring-solutions
[release managers]: https://gitlab.com/gitlab-org/release-tools/blob/master/doc/release-manager.md
[started brainstorming]: https://gitlab.com/gitlab-org/gitlab-ce/issues/17826
[release process]: https://gitlab.com/gitlab-org/release-tools

---

[Return to Development documentation](README.md)
