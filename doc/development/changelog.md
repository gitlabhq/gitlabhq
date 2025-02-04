---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Changelog entries
---

This guide contains instructions for when and how to generate a changelog entry
file, as well as information and history about our changelog process.

## Overview

Each list item, or **entry**, in our
[`CHANGELOG.md`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/CHANGELOG.md)
file is generated from the subject line of a Git commit. Commits are included
when they contain the `Changelog` [Git trailer](https://git-scm.com/docs/git-interpret-trailers).
When generating the changelog, author and merge request details are added
automatically.

The `Changelog` trailer accepts the following values:

- `added`: New feature
- `fixed`: Bug fix
- `changed`: Feature change
- `deprecated`: New deprecation
- `removed`: Feature removal
- `security`: Security fix
- `performance`: Performance improvement
- `other`: Other

An example of a Git commit to include in the changelog is the following:

```plaintext
Update git vendor to gitlab

Now that we are using gitaly to compile git, the git version isn't known
from the manifest, instead we are getting the gitaly version. Update our
vendor field to be `gitlab` to avoid cve matching old versions.

Changelog: changed
```

If your merge request has multiple commits,
[make sure to add the `Changelog` entry to the first commit](changelog.md#how-to-generate-a-changelog-entry).
This ensures that the correct entry is generated when commits are squashed.

### Overriding the associated merge request

GitLab automatically links the merge request to the commit when generating the
changelog. If you want to override the merge request to link to, you can specify
an alternative merge request using the `MR` trailer:

```plaintext
Update git vendor to gitlab

Now that we are using gitaly to compile git, the git version isn't known
from the manifest, instead we are getting the gitaly version. Update our
vendor field to be `gitlab` to avoid cve matching old versions.

Changelog: changed
MR: https://gitlab.com/foo/bar/-/merge_requests/123
```

The value must be the full URL of the merge request.

### GitLab Enterprise changes

If a change is exclusively for GitLab Enterprise Edition, **you must add** the
trailer `EE: true`:

```plaintext
Update git vendor to gitlab

Now that we are using gitaly to compile git, the git version isn't known
from the manifest, instead we are getting the gitaly version. Update our
vendor field to be `gitlab` to avoid cve matching old versions.

Changelog: changed
MR: https://gitlab.com/foo/bar/-/merge_requests/123
EE: true
```

**Do not** add the trailer for changes that apply to both EE and CE.

## What warrants a changelog entry?

- Any change that introduces a database migration, whether it's regular, post,
  or data migration, **must** have a changelog entry, even if it is behind a
  disabled feature flag.
- [Security fixes](https://gitlab.com/gitlab-org/release/docs/blob/master/general/security/engineer.md)
  **must** have a changelog entry, with `Changelog` trailer set to `security`.
- Any user-facing change **must** have a changelog entry. Example: "GitLab now
  uses system fonts for all text."
- Any client-facing change to our REST and GraphQL APIs **must** have a changelog entry.
  See the [complete list what comprises a GraphQL breaking change](api_graphql_styleguide.md#breaking-changes).
- Any change that introduces an [advanced search migration](search/advanced_search_migration_styleguide.md#create-a-new-advanced-search-migration)
  **must** have a changelog entry.
- A fix for a regression introduced and then fixed in the same release (such as
  fixing a bug introduced during a monthly release candidate) **should not**
  have a changelog entry.
- Any developer-facing change (such as refactoring, technical debt remediation,
  or test suite changes) **should not** have a changelog entry. Example: "Reduce
  database records created during Cycle Analytics model spec."
- _Any_ contribution from a community member, no matter how small, **may** have
  a changelog entry regardless of these guidelines if the contributor wants one.
- Any [experiment](experiment_guide/_index.md) changes **should not** have a changelog entry.
- An MR that includes only documentation changes **should not** have a changelog entry.

For more information, see
[how to handle changelog entries with feature flags](feature_flags/_index.md#changelog).

## Writing good changelog entries

A good changelog entry should be descriptive and concise. It should explain the
change to a reader who has _zero context_ about the change. If you have trouble
making it both concise and descriptive, err on the side of descriptive.

- **Bad:** Go to a project order.
- **Good:** Show a user's starred projects at the top of the "Go to project"
  dropdown list.

The first example provides no context of where the change was made, or why, or
how it benefits the user.

- **Bad:** Copy (some text) to clipboard.
- **Good:** Update the "Copy to clipboard" tooltip to indicate what's being
  copied.

Again, the first example is too vague and provides no context.

- **Bad:** Fixes and Improves CSS and HTML problems in mini pipeline graph and
  builds dropdown list.
- **Good:** Fix tooltips and hover states in mini pipeline graph and builds
  dropdown list.

The first example is too focused on implementation details. The user doesn't
care that we changed CSS and HTML, they care about the _end result_ of those
changes.

- **Bad:** Strip out `nil`s in the Array of Commit objects returned from
  `find_commits_by_message_with_elastic`
- **Good:** Fix 500 errors caused by Elasticsearch results referencing
  garbage-collected commits

The first example focuses on _how_ we fixed something, not on _what_ it fixes.
The rewritten version clearly describes the _end benefit_ to the user (fewer 500
errors), and _when_ (searching commits with Elasticsearch).

Use your best judgement and try to put yourself in the mindset of someone
reading the compiled changelog. Does this entry add value? Does it offer context
about _where_ and _why_ the change was made?

## How to generate a changelog entry

Git trailers are added when committing your changes. This can be done using your
text editor of choice. Adding the trailer to an existing commit requires either
amending to the commit (if it's the most recent one), or an interactive rebase
using `git rebase -i`.

To update the last commit, run the following:

```shell
git commit --amend
```

You can then add the `Changelog` trailer to the commit message. If you had
already pushed prior commits to your remote branch, you have to force push
the new commit:

```shell
git push -f origin your-branch-name
```

To edit older (or multiple commits), use `git rebase -i HEAD~N` where `N` is the
last N number of commits to rebase. Let's say you have 3 commits on your branch:
A, B, and C. If you want to update commit B, you need to run:

```shell
git rebase -i HEAD~2
```

This starts an interactive rebase session for the last two commits. When
started, Git presents you with a text editor with contents along the lines of
the following:

```plaintext
pick B Subject of commit B
pick C Subject of commit C
```

To update commit B, change the word `pick` to `reword`, then save and quit the
editor. Once closed, Git presents you with a new text editor instance to edit
the commit message of commit B. Add the trailer, then save and quit the editor.
If all went well, commit B is now updated.

Since you changed commits that already exist in your remote branch, you must use
the `--force-with-lease` flag when pushing to your remote branch:

```shell
git push origin your-branch-name --force-with-lease
```

For more information about interactive rebases, take a look at
[the Git documentation](https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History).

---

[Return to Development documentation](_index.md)
