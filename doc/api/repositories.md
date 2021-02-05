---
stage: Create
group: Source Code
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments"
type: reference, api
---

# Repositories API **(CORE)**

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
| `id`        | integer/string | no       | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
| `path`      | string         | yes      | The path inside repository. Used to get content of subdirectories. |
| `ref`       | string         | yes      | The name of a repository branch or tag or if not given the default branch. |
| `recursive` | boolean        | yes      | Boolean value used to get a recursive tree (false by default). |
| `per_page`  | integer        | yes      | Number of results to show per page. If not specified, defaults to `20`. [Learn more on pagination](README.md#pagination). |

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
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
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
| `id`      | datatype | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
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
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
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

| Attribute  | Type           | Required | Description |
| :--------- | :------------- | :------- | :---------- |
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
| `from`     | string         | yes      | The commit SHA or branch name. |
| `to`       | string         | yes      | The commit SHA or branch name. |
| `straight` | boolean        | no       | Comparison method, `true` for direct comparison between `from` and `to` (`from`..`to`), `false` to compare using merge base (`from`...`to`)'. Default is `false`. |

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
| `id`       | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user. |
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
| `id`      | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
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

> - [Introduced](https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/351) in GitLab 13.9.
> - It's [deployed behind a feature flag](../user/feature_flags.md), disabled by default.
> - It's disabled on GitLab.com.
> - It's not yet recommended for production use.
> - To use it in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enable-or-disable-generating-changelog-data).

WARNING:
This feature might not be available to you. Check the **version history** note above for details.

Generate changelog data based on commits in a repository.

Given a version (using semantic versioning) and a range of commits,
GitLab generates a changelog for all commits that use a particular
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
| `from`    | string   | yes | The start of the range of commits (as a SHA) to use for generating the changelog. This commit itself isn't included in the list. |
| `to`      | string   | yes | The end of the range of commits (as a SHA) to use for the changelog. This commit _is_ included in the list. |
| `date`    | datetime | no | The date and time of the release, defaults to the current time. |
| `branch`  | string   | no | The branch to commit the changelog changes to, defaults to the project's default branch. |
| `trailer` | string   | no | The Git trailer to use for including commits, defaults to `Changelog`. |
| `file`    | string   | no | The file to commit the changes to, defaults to `CHANGELOG.md`. |
| `message` | string   | no | The commit message to produce when committing the changes, defaults to `Add changelog for version X` where X is the value of the `version` argument. |

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

You can specify a custom template in your configuration like so:

```yaml
---
template: >
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

The `author` and `merge_request` objects might not be present if the data couldn't
be determined (for example, when a commit was created without a corresponding merge
request).

### Enable or disable generating changelog data **(CORE ONLY)**

This feature is under development and not ready for production use. It is
deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../administration/feature_flags.md)
can enable it.

To enable it for a project:

```ruby
Feature.enable(:changelog_api, Project.find(id_of_the_project))
```

To disable it for a project:

```ruby
Feature.disable(:changelog_api, Project.find(id_of_the_project))
```
