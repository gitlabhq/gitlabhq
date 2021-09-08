# Generating changelog entries

From GitLab 14.0.0 onwards, [CHANGELOG.md](../CHANGELOG.md) is generated
by parsing [Git trailers](https://git-scm.com/docs/git-interpret-trailers)
in commit messages.

See [documentation](https://docs.gitlab.com/ee/development/changelog.html#how-to-generate-a-changelog-entry)
on how to generate changelog entries.

# Changelog archival

The current major release is always in [CHANGELOG.md](../CHANGELOG.md) at the
root of the repository.

From GitLab 10.0.0 onwards, we store all changelog entries for a major release
in their own file in this directory. For instance, the changelog entries for the
10.X series of GitLab are in [archive-10.md](archive-10.md). Releases prior to
10.0.0 have their changelogs archived in [archive.md](archive.md).

Changelogs for GitLab Enterprise Edition features (all tiers) are in the
corresponding `-ee` files, such as [CHANGELOG-EE.md](../CHANGELOG-EE.md) and
[archive-12-ee.md](archive-12-ee.md).
