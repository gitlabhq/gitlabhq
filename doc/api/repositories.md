---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments"
description: "Documentation for the REST API for Git repositories in GitLab."
title: Repositories API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

## List repository tree

Get a list of repository files and directories in a project. This endpoint can
be accessed without authentication if the repository is publicly accessible.

This command provides essentially the same features as the `git ls-tree`
command. For more information, refer to the section
[Tree Objects](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects.html#_tree_objects)
in the Git internals documentation.

WARNING:
This endpoint changed to [keyset-based pagination](rest/_index.md#keyset-based-pagination)
in GitLab 15.0. Iterating pages of results with a number (`?page=2`) is unsupported.

```plaintext
GET /projects/:id/repository/tree
```

Supported attributes:

| Attribute   | Type           | Required | Description |
| :---------- | :------------- | :------- | :---------- |
| `id`        | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `page_token` | string        | no       | The tree record ID at which to fetch the next page. Used only with keyset pagination. |
| `pagination` | string        | no       | If `keyset`, use the [keyset-based pagination method](rest/_index.md#keyset-based-pagination). |
| `path`      | string         | no       | The path inside the repository. Used to get content of subdirectories. |
| `per_page`  | integer        | no       | Number of results to show per page. If not specified, defaults to `20`. For more information, see [Pagination](rest/_index.md#pagination). |
| `recursive` | boolean        | no       | Boolean value used to get a recursive tree. Default is `false`. |
| `ref`       | string         | no       | The name of a repository branch or tag or, if not given, the default branch. |

```json
[
  {
    "id": "a1e8f8d745cc87e3a9248358d9352bb7f9a0aeba",
    "name": "html",
    "type": "tree",
    "path": "files/html",
    "mode": "040000"
  },
  {
    "id": "4535904260b1082e14f867f7a24fd8c21495bde3",
    "name": "images",
    "type": "tree",
    "path": "files/images",
    "mode": "040000"
  },
  {
    "id": "31405c5ddef582c5a9b7a85230413ff90e2fe720",
    "name": "js",
    "type": "tree",
    "path": "files/js",
    "mode": "040000"
  },
  {
    "id": "cc71111cfad871212dc99572599a568bfe1e7e00",
    "name": "lfs",
    "type": "tree",
    "path": "files/lfs",
    "mode": "040000"
  },
  {
    "id": "fd581c619bf59cfdfa9c8282377bb09c2f897520",
    "name": "markdown",
    "type": "tree",
    "path": "files/markdown",
    "mode": "040000"
  },
  {
    "id": "23ea4d11a4bdd960ee5320c5cb65b5b3fdbc60db",
    "name": "ruby",
    "type": "tree",
    "path": "files/ruby",
    "mode": "040000"
  },
  {
    "id": "7d70e02340bac451f281cecf0a980907974bd8be",
    "name": "whitespace",
    "type": "blob",
    "path": "files/whitespace",
    "mode": "100644"
  }
]
```

## Get a blob from repository

Allows you to receive information, such as size and content, about blobs in a repository.
Blob content is Base64 encoded. This endpoint can be accessed without authentication,
if the repository is publicly accessible.

```plaintext
GET /projects/:id/repository/blobs/:sha
```

Supported attributes:

| Attribute | Type           | Required | Description |
| :-------- | :------------- | :------- | :---------- |
| `id`      | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `sha`     | string         | yes      | The blob SHA. |

## Raw blob content

Get the raw file contents for a blob, by blob SHA. This endpoint can be accessed
without authentication if the repository is publicly accessible.

```plaintext
GET /projects/:id/repository/blobs/:sha/raw
```

Supported attributes:

| Attribute | Type     | Required | Description |
| :-------- | :------- | :------- | :---------- |
| `id`      | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `sha`     | string | yes      | The blob SHA. |

## Get file archive

Get an archive of the repository. This endpoint can be accessed without
authentication if the repository is publicly accessible.

For GitLab.com users, this endpoint has a rate limit threshold of 5 requests per minute.

```plaintext
GET /projects/:id/repository/archive[.format]
```

`format` is an optional suffix for the archive format, and defaults to
`tar.gz`. For example, specifying `archive.zip` sends an archive in ZIP format.
Available options are:

- `bz2`
- `tar`
- `tar.bz2`
- `tar.gz`
- `tb2`
- `tbz`
- `tbz2`
- `zip`

Supported attributes:

| Attribute   | Type           | Required | Description           |
|:------------|:---------------|:---------|:----------------------|
| `id`        | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `path`      | string         | no       | The subpath of the repository to download. If an empty string, defaults to the whole repository.  |
| `sha`       | string         | no       | The commit SHA to download. A tag, branch reference, or SHA can be used. If not specified, defaults to the tip of the default branch. |
| `include_lfs_blobs` | boolean | no | Determines whether LFS objects are included in the archive. Default is `true`. When set to `false`, LFS objects are excluded. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.com/api/v4/projects/<project_id>/repository/archive?sha=<commit_sha>&path=<path>"
```

## Compare branches, tags or commits

This endpoint can be accessed without authentication if the repository is
publicly accessible. Diffs can have an empty diff string if
[diff limits](../development/merge_request_concepts/diffs/_index.md#diff-limits) are reached.

```plaintext
GET /projects/:id/repository/compare
```

Supported attributes:

| Attribute         | Type           | Required | Description |
| :---------        | :------------- | :------- | :---------- |
| `id`              | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `from`            | string         | yes      | The commit SHA or branch name. |
| `to`              | string         | yes      | The commit SHA or branch name. |
| `from_project_id` | integer        | no       | The ID to compare from. |
| `straight`        | boolean        | no       | Comparison method: `true` for direct comparison between `from` and `to` (`from`..`to`), `false` to compare using merge base (`from`...`to`)'. Default is `false`. |
| `unidiff`           | boolean | No       | Present diffs in the [unified diff](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html) format. Default is false. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610) in GitLab 16.5.     |

```plaintext
GET /projects/:id/repository/compare?from=main&to=feature
```

Example response:

```json
{
  "commit": {
    "id": "12d65c8dd2b2676fa3ac47d955accc085a37a9c1",
    "short_id": "12d65c8dd2b",
    "title": "JS fix",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "created_at": "2014-02-27T10:27:00+02:00"
  },
  "commits": [{
    "id": "12d65c8dd2b2676fa3ac47d955accc085a37a9c1",
    "short_id": "12d65c8dd2b",
    "title": "JS fix",
    "author_name": "Example User",
    "author_email": "user@example.com",
    "created_at": "2014-02-27T10:27:00+02:00"
  }],
  "diffs": [{
    "old_path": "files/js/application.js",
    "new_path": "files/js/application.js",
    "a_mode": null,
    "b_mode": "100644",
    "diff": "@@ -24,8 +24,10 @@\n //= require g.raphael-min\n //= require g.bar-min\n //= require branch-graph\n-//= require highlightjs.min\n-//= require ace/ace\n //= require_tree .\n //= require d3\n //= require underscore\n+\n+function fix() { \n+  alert(\"Fixed\")\n+}",
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false
  }],
  "compare_timeout": false,
  "compare_same_ref": false,
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/compare/ae73cb07c9eeaf35924a10f713b364d32b2dd34f...0b4bc9a49b562e85de7cc9e834518ea6828729b9"
}
```

## Contributors

> - `ref` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/156852) in GitLab 17.4.

Get repository contributors list. This endpoint can be accessed without
authentication if the repository is publicly accessible.

The commit count returned does not include merge commits.

```plaintext
GET /projects/:id/repository/contributors
```

Supported attributes:

| Attribute  | Type           | Required | Description |
| :--------- | :------------- | :------- | :---------- |
| `id`       | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `ref`      | string         | no       | The name of a repository branch or tag. If not given, the default branch. |
| `order_by` | string         | no       | Return contributors ordered by `name`, `email`, or `commits` (orders by commit date) fields. Default is `commits`. |
| `sort`     | string         | no       | Return contributors sorted in `asc` or `desc` order. Default is `asc`. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/7/repository/contributors"
```

Example response:

```json
[{
  "name": "Example User",
  "email": "example@example.com",
  "commits": 117,
  "additions": 0,
  "deletions": 0
}, {
  "name": "Sample User",
  "email": "sample@example.com",
  "commits": 33,
  "additions": 0,
  "deletions": 0
}]
```

## Merge Base

Get the common ancestor for 2 or more refs, such as commit SHAs, branch names, or tags.

```plaintext
GET /projects/:id/repository/merge_base
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ---------------------------------------------------------------------------------- |
| `id`      | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `refs`    | array          | yes      | The refs to find the common ancestor of. Accepts multiple refs.                    |

Example request, with the refs truncated for readability:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/merge_base?refs[]=304d257d&refs[]=0031876f"
```

Example response:

```json
{
  "id": "1a0b36b3cdad1d2ee32457c102a8c0b7056fa863",
  "short_id": "1a0b36b3",
  "title": "Initial commit",
  "created_at": "2014-02-27T08:03:18.000Z",
  "parent_ids": [],
  "message": "Initial commit\n",
  "author_name": "Example User",
  "author_email": "user@example.com",
  "authored_date": "2014-02-27T08:03:18.000Z",
  "committer_name": "Example User",
  "committer_email": "user@example.com",
  "committed_date": "2014-02-27T08:03:18.000Z"
}
```

## Add changelog data to a changelog file

> - Commit range limits [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/89032) in GitLab 15.1 [with a flag](../administration/feature_flags.md) named `changelog_commits_limitation`. Disabled by default.
> - [Enabled on GitLab.com and by default on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/33893) in GitLab 15.3.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/364101) in GitLab 17.3. Feature flag `changelog_commits_limitation` removed.

Generate changelog data based on commits in a repository.

Given a [semantic version](https://semver.org/) and a range
of commits, GitLab generates a changelog for all commits that use a particular
[Git trailer](https://git-scm.com/docs/git-interpret-trailers). GitLab adds
a new Markdown-formatted section to a changelog file in the Git repository of
the project. The output format can be customized.

For performance and security reasons, parsing the changelog configuration is limited to `2` seconds.
This limitation helps prevent potential DoS attacks from malformed changelog templates.
If the request times out, consider reducing the size of your `changelog_config.yml` file.

For user-facing documentation, see [Changelogs](../user/project/changelogs.md).

```plaintext
POST /projects/:id/repository/changelog
```

### Supported attributes

Changelogs support these attributes:

| Attribute | Type     | Required   | Description |
| :-------- | :------- | :--------- | :---------- |
| `version` | string   | yes | The version to generate the changelog for. The format must follow [semantic versioning](https://semver.org/). |
| `branch`  | string   | no | The branch to commit the changelog changes to. Defaults to the project's default branch. |
| `config_file` | string   | no | Path to the changelog configuration file in the project's Git repository. Defaults to `.gitlab/changelog_config.yml`. |
| `date`    | datetime | no | The date and time of the release. Defaults to the current time. |
| `file`    | string   | no | The file to commit the changes to. Defaults to `CHANGELOG.md`. |
| `from`    | string   | no | The SHA of the commit that marks the beginning of the range of commits to include in the changelog. This commit isn't included in the changelog. |
| `message` | string   | no | The commit message to use when committing the changes. Defaults to `Add changelog for version X`, where `X` is the value of the `version` argument. |
| `to`      | string   | no | The SHA of the commit that marks the end of the range of commits to include in the changelog. This commit _is_ included in the changelog. Defaults to the branch specified in the `branch` attribute. Limited to 15000 commits. |
| `trailer` | string   | no | The Git trailer to use for including commits. Defaults to `Changelog`. Case-sensitive: `Example` does not match `example` or `eXaMpLE`. |

### Requirements for `from` attribute

If the `from` attribute is unspecified, GitLab uses the Git tag of the last
stable version that came before the version specified in the `version`
attribute. For GitLab to extract version numbers from tag names, Git tag names
must follow a specific format. By default, GitLab considers tags using these formats:

- `vX.Y.Z`
- `X.Y.Z`

Where `X.Y.Z` is a version that follows [semantic versioning](https://semver.org/).
For example, consider a project with the following tags:

- `v1.0.0-pre1`
- `v1.0.0`
- `v1.1.0`
- `v2.0.0`

If the `version` attribute is `2.1.0`, GitLab uses tag `v2.0.0`. And when the
version is `1.1.1`, or `1.2.0`, GitLab uses tag `v1.1.0`. The tag `v1.0.0-pre1` is
never used, because pre-release tags are ignored.

The `version` attribute can start with `v`. For example: `v1.0.0`.
The response is the same as for `version` value `1.0.0`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/437616) in GitLab 17.0.

If `from` is unspecified and no tag to use is found, the API produces an error.
To solve such an error, you must explicitly specify a value for the `from`
attribute.

### Migrating from a manually-managed changelog file to Git trailers

When you migrate from an existing manually-managed changelog file to one that uses Git trailers,
make sure that the changelog file matches [the expected format](../user/project/changelogs.md).
Otherwise, new changelog entries added by the API might be inserted in an unexpected position.
For example, if the version values in the manually-managed changelog file are specified as `vX.Y.Z`
instead of `X.Y.Z`, then new changelog entries added using Git trailers are appended to the end of
the changelog file.

[Issue 444183](https://gitlab.com/gitlab-org/gitlab/-/issues/444183) proposes customizing the version header format in changelog files.
However, until that issue has been completed, the expected version header format in changelog files is `X.Y.Z`.

### Examples

These examples use [cURL](https://curl.se/) to perform HTTP requests.
The example commands use these values:

- **Project ID**: 42
- **Location**: hosted on GitLab.com
- **Example API token**: `token`

This command generates a changelog for version `1.0.0`.

The commit range:

- Starts with the tag of the last release.
- Ends with the last commit on the target branch. The default target branch is
  the project's default branch.

If the last tag is `v0.9.0` and the default branch is `main`, the range of commits
included in this example is `v0.9.0..main`:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: token" \
  --data "version=1.0.0" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

To generate the data on a different branch, specify the `branch` parameter. This
command generates data from the `foo` branch:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: token" \
  --data "version=1.0.0&branch=foo" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

To use a different trailer, use the `trailer` parameter:

```shell
curl --request POST --header "PRIVATE-TOKEN: token" \
  --data "version=1.0.0&trailer=Type" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

To store the results in a different file, use the `file` parameter:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: token" \
  --data "version=1.0.0&file=NEWS" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

## Generate changelog data

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172842) authentication through [CI/CD job token](../ci/jobs/ci_job_token.md) in GitLab 17.7.

Generate changelog data based on commits in a repository, without committing
them to a changelog file.

Works exactly like `POST /projects/:id/repository/changelog`, except the changelog
data isn't committed to any changelog file.

```plaintext
GET /projects/:id/repository/changelog
```

Supported attributes:

| Attribute | Type     | Required   | Description |
| :-------- | :------- | :--------- | :---------- |
| `version` | string   | yes | The version to generate the changelog for. The format must follow [semantic versioning](https://semver.org/). |
| `config_file` | string   | no | The path of changelog configuration file in the project's Git repository. Defaults to `.gitlab/changelog_config.yml`. |
| `date`    | datetime | no | The date and time of the release. Uses ISO 8601 format. Example: `2016-03-11T03:45:40Z`. Defaults to the current time. |
| `from`    | string   | no | The start of the range of commits (as a SHA) to use for generating the changelog. This commit itself isn't included in the list. |
| `to`      | string   | no | The end of the range of commits (as a SHA) to use for the changelog. This commit _is_ included in the list. Defaults to the HEAD of the default project branch. |
| `trailer` | string   | no | The Git trailer to use for including commits. Defaults to `Changelog`. |

```shell
curl --header "PRIVATE-TOKEN: token" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog?version=1.0.0"
```

Example response, with line breaks added for readability:

```json
{
  "notes": "## 1.0.0 (2021-11-17)\n\n### feature (2 changes)\n\n-
    [Title 2](namespace13/project13@ad608eb642124f5b3944ac0ac772fecaf570a6bf)
    ([merge request](namespace13/project13!2))\n-
    [Title 1](namespace13/project13@3c6b80ff7034fa0d585314e1571cc780596ce3c8)
    ([merge request](namespace13/project13!1))\n"
}
```

## Related topics

- User documentation for [changelogs](../user/project/changelogs.md)
- Developer documentation for [changelog entries](../development/changelog.md) in GitLab
