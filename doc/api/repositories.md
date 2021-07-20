---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, api
---

# Repositories API **(FREE)**

## List repository tree

Get a list of repository files and directories in a project. This endpoint can
be accessed without authentication if the repository is publicly accessible.

This command provides essentially the same functionality as the `git ls-tree` command. For more information, see the section _Tree Objects_ in the [Git internals documentation](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects/#_tree_objects).

```plaintext
GET /projects/:id/repository/tree
```

Supported attributes:

| Attribute   | Type           | Required | Description |
| :---------- | :------------- | :------- | :---------- |
| `id`        | integer/string | no       | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `path`      | string         | yes      | The path inside repository. Used to get content of subdirectories. |
| `ref`       | string         | yes      | The name of a repository branch or tag or if not given the default branch. |
| `recursive` | boolean        | yes      | Boolean value used to get a recursive tree (false by default). |
| `per_page`  | integer        | yes      | Number of results to show per page. If not specified, defaults to `20`. [Learn more on pagination](index.md#pagination). |

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

Allows you to receive information about blob in repository like size and
content. Note that blob content is Base64 encoded. This endpoint can be accessed
without authentication if the repository is publicly accessible.

```plaintext
GET /projects/:id/repository/blobs/:sha
```

Supported attributes:

| Attribute | Type           | Required | Description |
| :-------- | :------------- | :------- | :---------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `sha`     | string         | yes      | The blob SHA. |

## Raw blob content

Get the raw file contents for a blob by blob SHA. This endpoint can be accessed
without authentication if the repository is publicly accessible.

```plaintext
GET /projects/:id/repository/blobs/:sha/raw
```

Supported attributes:

| Attribute | Type     | Required | Description |
| :-------- | :------- | :------- | :---------- |
| `id`      | datatype | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `sha`     | datatype | yes      | The blob SHA. |

## Get file archive

> Support for [including Git LFS blobs](../topics/git/lfs/index.md#lfs-objects-in-project-archives) was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15079) in GitLab 13.5.

Get an archive of the repository. This endpoint can be accessed without
authentication if the repository is publicly accessible.

This endpoint has a rate limit threshold of 5 requests per minute for GitLab.com users.

```plaintext
GET /projects/:id/repository/archive[.format]
```

`format` is an optional suffix for the archive format. Default is
`tar.gz`. Options are `tar.gz`, `tar.bz2`, `tbz`, `tbz2`, `tb2`,
`bz2`, `tar`, and `zip`. For example, specifying `archive.zip`
would send an archive in ZIP format.

Supported attributes:

| Attribute   | Type           | Required | Description           |
|:------------|:---------------|:---------|:----------------------|
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `sha`       | string         | no       | The commit SHA to download. A tag, branch reference, or SHA can be used. This defaults to the tip of the default branch if not specified. |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.com/api/v4/projects/<project_id>/repository/archive?sha=<commit_sha>"
```

## Compare branches, tags or commits

This endpoint can be accessed without authentication if the repository is
publicly accessible. Note that diffs could have an empty diff string if [diff limits](../development/diffs.md#diff-limits) are reached.

```plaintext
GET /projects/:id/repository/compare
```

Supported attributes:

| Attribute         | Type           | Required | Description |
| :---------        | :------------- | :------- | :---------- |
| `id`              | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `from`            | string         | yes      | The commit SHA or branch name. |
| `to`              | string         | yes      | The commit SHA or branch name. |
| `from_project_id` | integer        | no       | The ID to compare from |
| `straight`        | boolean        | no       | Comparison method, `true` for direct comparison between `from` and `to` (`from`..`to`), `false` to compare using merge base (`from`...`to`)'. Default is `false`. |

```plaintext
GET /projects/:id/repository/compare?from=master&to=feature
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
    "diff": "--- a/files/js/application.js\n+++ b/files/js/application.js\n@@ -24,8 +24,10 @@\n //= require g.raphael-min\n //= require g.bar-min\n //= require branch-graph\n-//= require highlightjs.min\n-//= require ace/ace\n //= require_tree .\n //= require d3\n //= require underscore\n+\n+function fix() { \n+  alert(\"Fixed\")\n+}",
    "new_file": false,
    "renamed_file": false,
    "deleted_file": false
  }],
  "compare_timeout": false,
  "compare_same_ref": false
}
```

## Contributors

Get repository contributors list. This endpoint can be accessed without
authentication if the repository is publicly accessible.

```plaintext
GET /projects/:id/repository/contributors
```

WARNING:
The `additions` and `deletions` attributes are deprecated [as of GitLab 13.4](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/39653), because they [always return `0`](https://gitlab.com/gitlab-org/gitlab/-/issues/233119).

Supported attributes:

| Attribute  | Type           | Required | Description |
| :--------- | :------------- | :------- | :---------- |
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) owned by the authenticated user. |
| `order_by` | string         | no       | Return contributors ordered by `name`, `email`, or `commits` (orders by commit date) fields. Default is `commits`. |
| `sort`     | string         | no       | Return contributors sorted in `asc` or `desc` order. Default is `asc`. |

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

Get the common ancestor for 2 or more refs (commit SHAs, branch names or tags).

```plaintext
GET /projects/:id/repository/merge_base
```

| Attribute | Type           | Required | Description |
| --------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](index.md#namespaced-path-encoding) |
| `refs`    | array          | yes      | The refs to find the common ancestor of, multiple refs can be passed            |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/repository/merge_base?refs[]=304d257dcb821665ab5110318fc58a007bd104ed&refs[]=0031876facac3f2b2702a0e53a26e89939a42209"
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

## Generate changelog data

> [Introduced](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/351) in GitLab 13.9.

Generate changelog data based on commits in a repository.

Given a version (using [semantic versioning](https://semver.org/)) and a range
of commits, GitLab generates a changelog for all commits that use a particular
[Git trailer](https://git-scm.com/docs/git-interpret-trailers).

The output of this process is a new section in a changelog file in the Git
repository of the given project. The output format is in Markdown, and can be
customized.

```plaintext
POST /projects/:id/repository/changelog
```

Supported attributes:

| Attribute | Type     | Required   | Description |
| :-------- | :------- | :--------- | :---------- |
| `version` | string   | yes | The version to generate the changelog for. The format must follow [semantic versioning](https://semver.org/). |
| `from`    | string   | no | The start of the range of commits (as a SHA) to use for generating the changelog. This commit itself isn't included in the list. |
| `to`      | string   | no | The end of the range of commits (as a SHA) to use for the changelog. This commit _is_ included in the list. Defaults to the branch specified in the `branch` attribute. |
| `date`    | datetime | no | The date and time of the release, defaults to the current time. |
| `branch`  | string   | no | The branch to commit the changelog changes to, defaults to the project's default branch. |
| `trailer` | string   | no | The Git trailer to use for including commits, defaults to `Changelog`. |
| `file`    | string   | no | The file to commit the changes to, defaults to `CHANGELOG.md`. |
| `message` | string   | no | The commit message to produce when committing the changes, defaults to `Add changelog for version X` where X is the value of the `version` argument. |

WARNING:
GitLab treats trailers case-sensitively. If you set the `trailer` field to
`Example`, GitLab _won't_ include commits that use the trailer `example`,
`eXaMpLE`, or anything else that isn't _exactly_ `Example`.

If the `from` attribute is unspecified, GitLab uses the Git tag of the last
stable version that came before the version specified in the `version`
attribute. This requires that Git tag names follow a specific format, allowing
GitLab to extract a version from the tag names. By default, GitLab considers
tags using these formats:

- `vX.Y.Z`
- `X.Y.Z`

Where `X.Y.Z` is a version that follows [semantic
versioning](https://semver.org/). For example, consider a project with the
following tags:

- v1.0.0-pre1
- v1.0.0
- v1.1.0
- v2.0.0

If the `version` attribute is `2.1.0`, GitLab uses tag v2.0.0. And when the
version is `1.1.1`, or `1.2.0`, GitLab uses tag v1.1.0. The tag `v1.0.0-pre1` is
never used, because pre-release tags are ignored.

If `from` is unspecified and no tag to use is found, the API produces an error.
To solve such an error, you must explicitly specify a value for the `from`
attribute.

### Examples

These examples use [cURL](https://curl.se/) to perform HTTP requests.
The example commands use these values:

- **Project ID**: 42
- **Location**: hosted on GitLab.com
- **Example API token**: `token`

This command generates a changelog for version `1.0.0`.

The commit range:

- Starts with the tag of the last release.
- Ends with the last commit on the target branch. The default target branch is the project's default branch.

If the last tag is `v0.9.0` and the default branch is `main`, the range of commits
included in this example is `v0.9.0..main`:

```shell
curl --header "PRIVATE-TOKEN: token" --data "version=1.0.0" "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

To generate the data on a different branch, specify the `branch` parameter. This
command generates data from the `foo` branch:

```shell
curl --header "PRIVATE-TOKEN: token" --data "version=1.0.0&branch=foo" "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

To use a different trailer, use the `trailer` parameter:

```shell
curl --header "PRIVATE-TOKEN: token" --data "version=1.0.0&trailer=Type" "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

To store the results in a different file, use the `file` parameter:

```shell
curl --header "PRIVATE-TOKEN: token" --data "version=1.0.0&file=NEWS" "https://gitlab.com/api/v4/projects/42/repository/changelog"
```

### How it works

Changelogs are generated based on commit titles. Commits are only included if
they contain a specific Git trailer. GitLab uses the value of this trailer to
categorize the changes.

GitLab uses Git trailers, because Git trailers are
supported by Git out of the box. We use commits as input, as this is the only
source of data every project uses. In addition, commits can be retrieved when
operating on a mirror. This is important for GitLab itself, because during a security
release we might need to include changes from both public projects and private
security mirrors.

Changelogs are generated by taking the title of the commits to include and using
these as the changelog entries. You can enrich entries with additional data,
such as a link to the merge request or details about the commit author. You can
[customize the format of a changelog](#customize-the-changelog-output) section with a template.

Trailers can be manually added while editing a commit message. To include a commit
using the default trailer of `Changelog` and categorize it as a feature, the
trailer could be added to a commit message like so:

```plaintext
<Commit message subject>

<Commit message description>

Changelog: feature
```

### Reverted commits

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/55537) in GitLab 13.10.

When generating a changelog for a range, GitLab ignores commits both added and
reverted in that range. Revert commits themselves _are_ included if they use the
Git trailer used for generating changelogs.

Imagine the following scenario: you have three commits: A, B, and C. To generate
changelogs, you use the default trailer `Changelog`. Both A and B use this
trailer. Commit C is a commit that reverts commit B. When generating a changelog
for this range, GitLab only includes commit A.

Revert commits are detected by looking for commits where the message contains
the pattern `This reverts commit SHA`, where `SHA` is the SHA of the commit that
is reverted.

If a revert commit includes the trailer used for generating changelogs
(`Changelog` in the above example), the revert commit itself _is_ included.

### Customize the changelog output

The output is customized using a YAML configuration file stored in your
project's Git repository. This file must reside in
`.gitlab/changelog_config.yml`.

You can set the following variables in this file:

- `date_format`: the date format to use in the title of the newly added
  changelog data. This uses regular `strftime` formatting.
- `template`: a custom template to use for generating the changelog data.
- `categories`: a hash that maps raw category names to the names to use in the
  changelog.

Using the default settings, generating a changelog results in a section along
the lines of the following:

```markdown
## 1.0.0 (2021-01-05)

### Features (4 changes)

- [Feature 1](gitlab-org/gitlab@123abc) by @alice ([merge request](gitlab-org/gitlab!123))
- [Feature 2](gitlab-org/gitlab@456abc) ([merge request](gitlab-org/gitlab!456))
- [Feature 3](gitlab-org/gitlab@234abc) by @steve
- [Feature 4](gitlab-org/gitlab@456)
```

Each section starts with a title that contains the version and release date.
While the format of the date can be customized, the rest of the title can't be
changed. When adding a new section, GitLab parses these titles to determine
where in the file the new section should be placed. GitLab sorts sections
according to their versions, not their dates.

Each section can have categories, each with their
corresponding changes. In the above example, "Features" is one such category.
You can customize the format of these sections.

The section names are derived from the values of the Git trailer used to include
or exclude commits.

For example, if the trailer to use is called `Changelog`,
and its value is `feature`, then the commit is grouped in the `feature`
category. The names of these raw values might differ from what you want to
show in a changelog, you can remap them. Let's say we use the `Changelog`
trailer and developers use the following values: `feature`, `bug`, and
`performance`.

You can remap these using the following YAML configuration file:

```yaml
---
categories:
  feature: Features
  bug: Bug fixes
  performance: Performance improvements
```

When generating the changelog data, the category titles are then `### Features`,
`### Bug fixes`, and `### Performance improvements`.

### Custom templates

The category sections are generated using a template. The default template is as
follows:

```plaintext
{% if categories %}
{% each categories %}
### {{ title }} ({% if single_change %}1 change{% else %}{{ count }} changes{% end %})

{% each entries %}
- [{{ title }}]({{ commit.reference }})\
{% if author.contributor %} by {{ author.reference }}{% end %}\
{% if merge_request %} ([merge request]({{ merge_request.reference }})){% end %}

{% end %}

{% end %}
{% else %}
No changes.
{% end %}
```

The `{% ... %}` tags are for statements, and `{{ ... }}` is used for printing
data. Statements must be terminated using a `{% end %}` tag. Both the `if` and
`each` statements require a single argument.

For example, if we have a variable `valid`, and we want to display "yes"
when this value is true, and display "nope" otherwise. We can do so as follows:

```plaintext
{% if valid %}
yes
{% else %}
nope
{% end %}
```

The use of `else` is optional. A value is considered true when it's a non-empty
value or boolean `true`. Empty arrays and hashes are considered false.

Looping is done using `each`, and variables inside a loop are scoped to it.
Referring to the current value in a loop is done using the variable tag `{{ it
}}`. Other variables read their value from the current loop value. Take
this template for example:

```plaintext
{% each users %}
{{name}}
{% end %}
```

Assuming `users` is an array of objects, each with a `name` field, this would
then print the name of every user.

Using variable tags, you can access nested objects. For example, `{{
users.0.name }}` prints the name of the first user in the `users` variable.

If a line ends in a backslash, the next newline is ignored. This allows you to
wrap code across multiple lines, without introducing unnecessary newlines in the
Markdown output.

Tags that use `{%` and `%}` (known as expression tags) consume the newline that
directly follows them, if any. This means that this:

```plaintext
---
{% if foo %}
bar
{% end %}
---
```

Compiles into this:

```plaintext
---
bar
---
```

Instead of this:

```plaintext
---

bar

---
```

You can specify a custom template in your configuration like so:

```yaml
---
template: |
  {% if categories %}
  {% each categories %}
  ### {{ title }}

  {% each entries %}
  - [{{ title }}]({{ commit.reference }})\
  {% if author.contributor %} by {{ author.reference }}{% end %}

  {% end %}

  {% end %}
  {% else %}
  No changes.
  {% end %}
```

Note that when specifying the template you should use `template: |` and not
`template: >`, as the latter doesn't preserve newlines in the template.

### Template data

At the top level, the following variable is available:

- `categories`: an array of objects, one for every changelog category.

In a category, the following variables are available:

- `title`: the title of the category (after it has been remapped).
- `count`: the number of entries in this category.
- `single_change`: a boolean that indicates if there is only one change (`true`),
  or multiple changes (`false`).
- `entries`: the entries that belong to this category.

In an entry, the following variables are available (here `foo.bar` means that
`bar` is a sub-field of `foo`):

- `title`: the title of the changelog entry (this is the commit title).
- `commit.reference`: a reference to the commit, for example,
  `gitlab-org/gitlab@0a4cdd86ab31748ba6dac0f69a8653f206e5cfc7`.
- `commit.trailers`: an object containing all the Git trailers that were present
  in the commit body.
- `author.reference`: a reference to the commit author (for example, `@alice`).
- `author.contributor`: a boolean set to `true` when the author is an external
  contributor, otherwise this is set to `false`.
- `merge_request.reference`: a reference to the merge request that first
  introduced the change (for example, `gitlab-org/gitlab!50063`).

The `author` and `merge_request` objects might not be present if the data
couldn't be determined. For example, when a commit is created without a
corresponding merge request, no merge request is displayed.

### Customize the tag format when extracting versions

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56889) in GitLab 13.11.

GitLab uses a regular expression (using the
[re2](https://github.com/google/re2/) engine and syntax) to extract a semantic
version from tag names. The default regular expression is:

```plaintext
^v?(?P<major>0|[1-9]\d*)\.(?P<minor>0|[1-9]\d*)\.(?P<patch>0|[1-9]\d*)(?:-(?P<pre>(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+(?P<meta>[0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$
```

This regular expression is based on the official
[semantic versioning](https://semver.org/) regular expression, and also includes
support for tag names that start with the letter `v`.

If your project uses a different format for tags, you can specify a different
regular expression. The regular expression used _must_ produce the following
capture groups. If any of these capture groups are missing, the tag is ignored:

- `major`
- `minor`
- `patch`

The following capture groups are optional:

- `pre`: If set, the tag is ignored. Ignoring `pre` tags ensures release candidate
  tags and other pre-release tags are not considered when determining the range of
  commits to generate a changelog for.
- `meta`: (Optional) Specifies build metadata.

Using this information, GitLab builds a map of Git tags and their release
versions. It then determines what the latest tag is, based on the version
extracted from each tag.

To specify a custom regular expression, use the `tag_regex` setting in your
changelog configuration YAML file. For example, this pattern matches tag names
such as `version-1.2.3` but not `version-1.2`.

```yaml
---
tag_regex: '^version-(?P<major>\d+)\.(?P<minor>\d+)\.(?P<patch>\d+)$'
```

To test if your regular expression is working, you can use websites such as
[regex101](https://regex101.com/). If the regular expression syntax is invalid,
an error is produced when generating a changelog.
