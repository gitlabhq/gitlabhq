---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Source Code - Gitaly Touch Points

## RPCs

Gitaly is a wrapper around the `git` binary, running in a [Gitaly Cluster](../../../administration/gitaly/index.md). It provides managed access to the file system housing the `git` repositories, using Go Remote Procedure Calls (RPCs). Other functions are access optimization, caching, and a form of pagination against the file system.

The comprehensive [Beginner's guide to Gitaly contributions](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/beginners_guide.md) is focused on making updates to Gitaly, and offers many insights into how to understand the Gitaly code.

All access to Gitaly from other parts of GitLab are through Create: Source Code endpoints:

## The `Commit` model

After a call is made to Gitaly, Git `commit` information is stored in memory. This information is wrapped by the [Ruby `Commit` Model](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/commit.rb), which is a wrapper around [`Gitlab::Git::Commit`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/git/commit.rb).

The `Commit` model acts like an ActiveRecord object, but it does not have a PostgreSQL backend. Instead, it maps back to Gitaly RPCs.

## Rugged Patches

Historically in GitLab, access to the server-based `git` repositories was provided through the [rugged](https://github.com/libgit2/rugged) RubyGem, which provides Ruby bindings to `libgit2`. This was further extended by what is termed "Rugged Patches", [a set of extensions to the Rugged library](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/57317). Rugged implementations of some of the most commonly-used RPCs can be [enabled via feature flags](../../gitaly.md#legacy-rugged-code).

Rugged access requires the use of a NFS file system, a direction GitLab is moving away from in favor of Gitaly Cluster. Rugged has been proposed for [deprecation and removal](https://gitlab.com/gitlab-org/gitaly/-/issues/1690). Several large customers are still using NFS, and a specific removal date is not planned at this point.
