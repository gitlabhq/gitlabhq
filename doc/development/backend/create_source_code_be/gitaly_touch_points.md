---
stage: Create
group: Source Code
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Source Code - Gitaly Touch Points
---

## RPCs

Gitaly is a wrapper around the `git` binary, running in a [Gitaly Cluster](../../../administration/gitaly/_index.md). It provides managed access to the file system housing the `git` repositories, using Go Remote Procedure Calls (RPCs). Other functions are access optimization, caching, and a form of pagination against the file system.

The [Beginner's guide to Gitaly contributions](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/beginners_guide.md) is focused on making updates to Gitaly, and offers many insights into how to understand the Gitaly code.

All access to Gitaly from other parts of GitLab are through Create: Source Code endpoints:

## The `Commit` model

After a call is made to Gitaly, Git `commit` information is stored in memory. This information is wrapped by the [Ruby `Commit` Model](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/commit.rb), which is a wrapper around [`Gitlab::Git::Commit`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/git/commit.rb).

The `Commit` model acts like an ActiveRecord object, but it does not have a PostgreSQL backend. Instead, it maps back to Gitaly RPCs.
