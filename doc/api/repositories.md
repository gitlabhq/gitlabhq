---
stage: Create
group: Source Code
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Documentation for the REST API for Git repositories in GitLab.
title: Repositories API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use this API to manage [Git repositories](../user/project/repository/_index.md).

## List repository tree

Get a list of repository files and directories in a project. This endpoint can
be accessed without authentication if the repository is publicly accessible.

This command provides essentially the same features as the `git ls-tree`
command. For more information, refer to the section
[Tree Objects](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects.html#_tree_objects)
in the Git internals documentation.

{{< alert type="warning" >}}

GitLab version 17.7 changes the error handling behavior when a requested path is not found.
The endpoint now returns a status code `404 Not Found`. Previously, the status code was `200 OK`.

If your implementation relies on receiving a `200` status code with an empty array for
missing paths, you must update your error handling to handle the new `404` responses.

{{< /alert >}}

```plaintext
GET /projects/:id/repository/tree
```

Supported attributes:

| Attribute    | Type              | Required | Description |
|--------------|-------------------|----------|-------------|
| `id`         | integer or string | Yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project. |
| `page_token` | string            | No       | Tree record ID at which to fetch the next page. Used only with keyset pagination. |
| `pagination` | string            | No       | If `keyset`, use the [keyset-based pagination method](rest/_index.md#keyset-based-pagination). |
| `path`       | string            | No       | Path inside the repository. Used to get content of subdirectories. |
| `per_page`   | integer           | No       | Number of results to show per page. If not specified, defaults to `20`. For more information, see [Pagination](rest/_index.md#pagination). |
| `recursive`  | boolean           | No       | If `true`, get a recursive tree. Default is `false`. |
| `ref`        | string            | No       | Name of a repository branch or tag. If not specified, uses the default branch. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and an array of tree objects.

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/tree"
```

Example response:

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

For blobs larger than 10 MB, this endpoint has a rate limit of 5 requests per minute.

```plaintext
GET /projects/:id/repository/blobs/:sha
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project. |
| `sha`     | string            | Yes      | Blob SHA.   |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute  | Type    | Description |
|------------|---------|-------------|
| `content`  | string  | Base64 encoded blob content. |
| `encoding` | string  | Encoding used for the blob content. |
| `sha`      | string  | Blob SHA.   |
| `size`     | integer | Size of the blob in bytes. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/blobs/79f7bbd25901e8334750839545a9bd021f0e4c83"
```

Example response:

```json
{
  "size": 1476,
  "encoding": "base64",
  "content": "VGhpcyBpcyBhIGJpbmFyeSBmaWxl",
  "sha": "79f7bbd25901e8334750839545a9bd021f0e4c83"
}
```

## Get raw blob content

Get the raw file contents for a blob, by blob SHA. This endpoint can be accessed
without authentication if the repository is publicly accessible.

```plaintext
GET /projects/:id/repository/blobs/:sha/raw
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project. |
| `sha`     | string            | Yes      | Blob SHA.   |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/13083/repository/blobs/79f7bbd25901e8334750839545a9bd021f0e4c83/raw"
```

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

| Attribute           | Type              | Required | Description |
|---------------------|-------------------|----------|-------------|
| `id`                | integer or string | Yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project. |
| `exclude_paths`     | string            | No       | Comma-separated list of paths to exclude from the archive. |
| `include_lfs_blobs` | boolean           | No       | If `true`, LFS objects are included in the archive. When set to `false`, LFS objects are excluded. Default is `true`. |
| `path`              | string            | No       | Subpath of the repository to download. If an empty string, defaults to the whole repository. |
| `sha`               | string            | No       | Commit SHA to download. Accepts a tag, branch reference, or SHA. If not specified, defaults to the tip of the default branch. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.com/api/v4/projects/<project_id>/repository/archive?sha=<commit_sha>&path=<path>&exclude_paths=<path1,path2>"
```

## Compare branches, tags, or commits

{{< history >}}

- `collapsed` and `too_large` response attributes [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/199633) in GitLab 18.4.

{{< /history >}}

This endpoint can be accessed without authentication if the repository is
publicly accessible. Diffs can have an empty diff string if
diff limits are reached.

```plaintext
GET /projects/:id/repository/compare
```

Supported attributes:

| Attribute         | Type              | Required | Description |
|-------------------|-------------------|----------|-------------|
| `from`            | string            | Yes      | Commit SHA or branch name. |
| `id`              | integer or string | Yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project. |
| `to`              | string            | Yes      | Commit SHA or branch name. |
| `from_project_id` | integer           | No       | ID to compare from. |
| `straight`        | boolean           | No       | If `true`, comparison method is direct comparison between `from` and `to` (`from`..`to`). If `false`, compare using merge base (`from`...`to`). Default is `false`. |
| `unidiff`         | boolean           | No       | If `true`, present diffs in the [unified diff](https://www.gnu.org/software/diffutils/manual/html_node/Detailed-Unified.html) format. Default is `false`. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130610) in GitLab 16.5. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                | Type         | Description |
|--------------------------|--------------|-------------|
| `commit`                 | object       | Details of the latest commit in the comparison. |
| `commits`                | object array | List of commits included in the comparison. |
| `commits[].author_email` | string       | Commit author's email address. |
| `commits[].author_name`  | string       | Commit author's name. |
| `commits[].created_at`   | datetime     | Commit creation timestamp. |
| `commits[].id`           | string       | Full commit SHA. |
| `commits[].short_id`     | string       | Short commit SHA. |
| `commits[].title`        | string       | Commit title. |
| `compare_same_ref`       | boolean      | If `true`, comparison uses the same reference for both from and to. |
| `compare_timeout`        | boolean      | If `true`, comparison operation timed out. |
| `diffs`                  | object array | List of file differences. |
| `diffs[].a_mode`         | string       | Old file mode. |
| `diffs[].b_mode`         | string       | New file mode. |
| `diffs[].collapsed`      | boolean      | If `true`, file diffs are excluded but can be fetched on request. |
| `diffs[].deleted_file`   | boolean      | If `true`, file has been removed. |
| `diffs[].diff`           | string       | Diff content showing changes made to the file. |
| `diffs[].new_file`       | boolean      | If `true`, file has been added. |
| `diffs[].new_path`       | string       | New path of the file. |
| `diffs[].old_path`       | string       | Old path of the file. |
| `diffs[].renamed_file`   | boolean      | If `true`, file has been renamed. |
| `diffs[].too_large`      | boolean      | If `true`, file diffs are excluded and cannot be retrieved. |
| `web_url`                | string       | Web URL for viewing the comparison. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/5/repository/compare?from=main&to=feature"
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
    "collapsed": false,
    "too_large": false,
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false
  }],
  "compare_timeout": false,
  "compare_same_ref": false,
  "web_url": "https://gitlab.example.com/janedoe/gitlab-foss/-/compare/ae73cb07c9eeaf35924a10f713b364d32b2dd34f...0b4bc9a49b562e85de7cc9e834518ea6828729b9"
}
```

## Get contributor list

{{< history >}}

- `ref` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/156852) in GitLab 17.4.

{{< /history >}}

Get repository contributors list. This endpoint can be accessed without
authentication if the repository is publicly accessible.

The commit count returned does not include merge commits.

```plaintext
GET /projects/:id/repository/contributors
```

Supported attributes:

| Attribute  | Type              | Required | Description |
|------------|-------------------|----------|-------------|
| `id`       | integer or string | Yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project. |
| `order_by` | string            | No       | Order contributors by `name`, `email`, or `commits` (number of commits). If not specified, contributors are ordered by commit date. |
| `ref`      | string            | No       | Name of a repository branch or tag. If not given, the default branch. |
| `sort`     | string            | No       | Return contributors sorted in `asc` or `desc` order. Default is `asc`. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute   | Type    | Description |
|-------------|---------|-------------|
| `additions` | integer | Number of line additions by the contributor. |
| `commits`   | integer | Number of commits by the contributor. |
| `deletions` | integer | Number of line deletions by the contributor. |
| `email`     | string  | Email address of the contributor. |
| `name`      | string  | Name of the contributor. |

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

## Get merge base

Get the common ancestor for 2 or more refs, such as commit SHAs, branch names, or tags.

```plaintext
GET /projects/:id/repository/merge_base
```

Supported attributes:

| Attribute | Type              | Required | Description |
|-----------|-------------------|----------|-------------|
| `id`      | integer or string | Yes      | ID or [URL-encoded path](rest/_index.md#namespaced-paths) of the project. |
| `refs`    | array             | Yes      | Refs to find the common ancestor of. Accepts multiple refs. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute           | Type     | Description |
|---------------------|----------|-------------|
| `author_email`      | string   | Author's email address. |
| `author_name`       | string   | Author's name. |
| `authored_date`     | datetime | Date when the commit was authored. |
| `committed_date`    | datetime | Date when the commit was committed. |
| `committer_email`   | string   | Committer's email address. |
| `committer_name`    | string   | Committer's name. |
| `created_at`        | datetime | Commit creation timestamp. |
| `extended_trailers` | object   | Extended information about Git trailers. |
| `id`                | string   | Full commit SHA. |
| `message`           | string   | Full commit message. |
| `parent_ids`        | array    | List of parent commit SHAs. |
| `short_id`          | string   | Short commit SHA. |
| `title`             | string   | Commit title. |
| `trailers`          | object   | Git trailers parsed from the commit message. |
| `web_url`           | string   | URL to view the commit in the GitLab web interface. |

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
  "committed_date": "2014-02-27T08:03:18.000Z",
  "trailers": {},
  "extended_trailers": {},
  "web_url": "https://gitlab.example.com/example-group/example-project/-/commit/1a0b36b3cdad1d2ee32457c102a8c0b7056fa863"
}
```

## Generate changelog data

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172842) authentication through [CI/CD job token](../ci/jobs/ci_job_token.md) in GitLab 17.7.
- `config_file_ref` attribute [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/426108) in GitLab 18.2.

{{< /history >}}

Generate changelog data based on commits in a repository, without committing
them to a changelog file.

Works exactly like `POST /projects/:id/repository/changelog`, except the changelog
data isn't committed to any changelog file.

```plaintext
GET /projects/:id/repository/changelog
```

Supported attributes:

| Attribute         | Type     | Required | Description |
|-------------------|----------|----------|-------------|
| `version`         | string   | Yes      | Version to generate the changelog for. Format must follow [semantic versioning](https://semver.org/). |
| `config_file`     | string   | No       | Path of changelog configuration file in the project's Git repository. Defaults to `.gitlab/changelog_config.yml`. |
| `config_file_ref` | string   | No       | Git reference (for example, branch) where the changelog configuration file is defined. Defaults to the default repository branch. |
| `date`            | datetime | No       | Date and time of the release. Uses ISO 8601 format. Example: `2016-03-11T03:45:40Z`. Defaults to the current time. |
| `from`            | string   | No       | Start of the range of commits (as a SHA) to use for generating the changelog. This commit itself isn't included in the list. |
| `to`              | string   | No       | End of the range of commits (as a SHA) to use for the changelog. This commit is included in the list. Defaults to the HEAD of the default project branch. |
| `trailer`         | string   | No       | Git trailer to use for including commits. Defaults to `Changelog`. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute | Type   | Description |
|-----------|--------|-------------|
| `notes`   | string | Generated changelog data in Markdown format. |

Example request:

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

## Add changelog data to file

{{< history >}}

- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/364101) in GitLab 17.3. Feature flag `changelog_commits_limitation` removed.
- `config_file_ref` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/426108) in GitLab 18.2.

{{< /history >}}

Generate changelog data based on commits in a repository and commit them to a changelog file.

Given a [semantic version](https://semver.org/) and a range
of commits, GitLab generates a changelog for all commits that use a particular
[Git trailer](https://git-scm.com/docs/git-interpret-trailers). GitLab adds
a new Markdown-formatted section to a changelog file in the Git repository of
the project. The output format can be customized.

For performance and security reasons, parsing the changelog configuration is limited to 2 seconds.
This limitation helps prevent potential DoS attacks from malformed changelog templates.
If the request times out, consider reducing the size of your `changelog_config.yml` file.

For user-facing documentation, see [Changelogs](../user/project/changelogs.md).

```plaintext
POST /projects/:id/repository/changelog
```

Changelogs support the following attributes:

| Attribute              | Type     | Required | Description |
|------------------------|----------|----------|-------------|
| `version` <sup>1</sup> | string   | Yes      | Version to generate the changelog for. Format must follow [semantic versioning](https://semver.org/). |
| `branch`               | string   | No       | Branch to commit the changelog changes to. Defaults to the project's default branch. |
| `config_file`          | string   | No       | Path to the changelog configuration file in the project's Git repository. Defaults to `.gitlab/changelog_config.yml`. |
| `config_file_ref`      | string   | No       | Git reference (for example, branch) where the changelog configuration file is defined. Defaults to the default repository branch. |
| `date`                 | datetime | No       | Date and time of the release. Defaults to the current time. |
| `file`                 | string   | No       | File to commit the changes to. Defaults to `CHANGELOG.md`. |
| `from` <sup>2</sup>    | string   | No       | SHA of the commit that marks the beginning of the range of commits to include in the changelog. This commit isn't included in the changelog. |
| `message`              | string   | No       | Commit message to use when committing the changes. Defaults to `Add changelog for version X`, where `X` is the value of the `version` argument. |
| `to`                   | string   | No       | SHA of the commit that marks the end of the range of commits to include in the changelog. This commit is included in the changelog. Defaults to the branch specified in the `branch` attribute. Limited to 15000 commits. |
| `trailer`              | string   | No       | Git trailer to use for including commits. Defaults to `Changelog`. Case-sensitive: `Example` does not match `example` or `eXaMpLE`. |

**Footnotes**:

1. The `version` attribute can include or omit the `v` prefix. Both `1.0.0` and `v1.0.0` produce identical results.
   [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/437616) in GitLab 17.0.

1. When `from` is unspecified, GitLab automatically finds the last stable version tag that precedes
   your specified version. GitLab recognizes tags in `X.Y.Z` or `vX.Y.Z` format, following semantic versioning.

   For example, if `version` is `2.1.0`, GitLab uses tag `v2.0.0`. When `version` is `1.1.1` or `1.2.0`,
   GitLab uses tag `v1.1.0`. Pre-release tags like `v1.0.0-pre1` are ignored.

   If no suitable tag is found, the API returns an error and you must explicitly specify the `from` attribute.

### Examples

These examples use [cURL](https://curl.se/) to perform HTTP requests.
The example commands use these values:

- Project ID: 42
- Location: hosted on GitLab.com
- Example API token: `token`

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

To specify a branch as a parameter, use the `to` attribute:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: token" \
  --url "https://gitlab.com/api/v4/projects/42/repository/changelog?version=1.0.0&to=release/x.x.x"
```

## Migrate from manual changelog files

When you migrate from an existing manually-managed changelog file to one that uses Git trailers,
make sure that the changelog file matches [the expected format](../user/project/changelogs.md).
Otherwise, new changelog entries added by the API might be inserted in an unexpected position.
For example, if the version values in the manually-managed changelog file are specified as `vX.Y.Z`
instead of `X.Y.Z`, then new changelog entries added using Git trailers are appended to the end of
the changelog file.

[Issue 444183](https://gitlab.com/gitlab-org/gitlab/-/issues/444183) proposes customizing the version
header format in changelog files.
However, until that issue has been completed, the expected version header format in changelog files is `X.Y.Z`.

## Health

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182220) in GitLab 17.10. Guarded behind the
  [`project_repositories_health`](https://gitlab.com/gitlab-org/gitlab/-/issues/521115) feature flag.
- New fields [added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/191263) in GitLab 18.1.

{{< /history >}}

Get statistics related to the health of a project repository.
This endpoint is rate-limited to 5 requests/hour per project.

```plaintext
GET /projects/:id/repository/health
```

Supported attributes:

| Attribute  | Type    | Required | Description                                                                            |
|------------|---------|----------|----------------------------------------------------------------------------------------|
| `generate` | boolean | No       | If `true`, a new health report should be generated. Set this if the endpoint returns `404`. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and repository health statistics.

Example request:

```shell
curl --header "PRIVATE-TOKEN: token" \
  --url "https://gitlab.com/api/v4/projects/42/repository/health"
```

Example response:

```json
{
  "size": 2619748827,
  "references": {
    "loose_count": 13,
    "packed_size": 333978,
    "reference_backend": "REFERENCE_BACKEND_FILES"
  },
  "objects": {
    "size": 2180475409,
    "recent_size": 2180453999,
    "stale_size": 21410,
    "keep_size": 0,
    "packfile_count": 1,
    "reverse_index_count": 1,
    "cruft_count": 0,
    "keep_count": 0,
    "loose_objects_count": 36,
    "stale_loose_objects_count": 36,
    "loose_objects_garbage_count": 0
  },
  "commit_graph": {
    "commit_graph_chain_length": 1,
    "has_bloom_filters": true,
    "has_generation_data": true,
    "has_generation_data_overflow": false
  },
  "bitmap": null,
  "multi_pack_index": {
    "packfile_count": 1,
    "version": 1
  },
  "multi_pack_index_bitmap": {
    "has_hash_cache": true,
    "has_lookup_table": true,
    "version": 1
  },
  "alternates": null,
  "is_object_pool": false,
  "last_full_repack": {
    "seconds": 1745892013,
    "nanos": 0
  },
  "updated_at": "2025-05-14T02:31:08.022Z"
}
```

For a description of each field in the response, see the
[`RepositoryInfoResponse`](https://gitlab.com/gitlab-org/gitaly/blob/fcb986a6482f82b088488db3ed7ca35adfa42fdc/proto/repository.proto#L444)
protobuf message.

## Related topics

- User documentation for [changelogs](../user/project/changelogs.md)
