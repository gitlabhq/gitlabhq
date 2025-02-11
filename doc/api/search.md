---
stage: Foundations
group: Global Search
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Search API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Every API call to search must be authenticated.

When [advanced search is enabled](../user/search/advanced_search.md#enable-advanced-search),
these additional scopes are available for the [advanced search](#advanced-search-api),
[group search](#group-search-api), and [project search](#project-search-api) APIs:

- `wiki_blobs`
- `commits`
- `blobs`
- `notes`

If you want to use basic search instead, see
[specify a search type](../user/search/_index.md#specify-a-search-type).

## Advanced search API

Search for a [term](../user/search/advanced_search.md#syntax) across the entire GitLab instance.
The response depends on the requested scope.

```plaintext
GET /search
```

| Attribute     | Type     | Required   | Description |
| ------------- | -------- | ---------- | ------------|
| `scope`       | string   | Yes | The scope to search in. Values include `projects`, `issues`, `merge_requests`, `milestones`, `snippet_titles`, and `users`. Additional scopes are `wiki_blobs`, `commits`, `blobs`, and `notes`. |
| `search`      | string   | Yes | The search term. |
| `confidential` | boolean   | No | Filter by confidentiality. Supports `issues` scope; other scopes are ignored. |
| `order_by`    | string   | No | Allowed values are `created_at` only. If not set, results are sorted by `created_at` in descending order for basic search, or by the most relevant documents for advanced search.|
| `sort`    | string   | No | Allowed values are `asc` or `desc` only. If not set, results are sorted by `created_at` in descending order for basic search, or by the most relevant documents for advanced search.|
| `state`       | string   | No | Filter by state. Supports `issues` and `merge_requests` scopes; other scopes are ignored. |
| `fields` | array of strings | No | Array of fields you wish to search, allowed values are `title` only. Supports `issues` and `merge_requests` scopes; other scopes are ignored. Premium and Ultimate only. |

### Scope: `projects`

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/search?scope=projects&search=flight"
```

Example response:

```json
[
  {
    "id": 6,
    "description": "Nobis sed ipsam vero quod cupiditate veritatis hic.",
    "name": "Flight",
    "name_with_namespace": "Twitter / Flight",
    "path": "flight",
    "path_with_namespace": "twitter/flight",
    "created_at": "2017-09-05T07:58:01.621Z",
    "default_branch": "main",
    "tag_list":[], //deprecated, use `topics` instead
    "topics":[],
    "ssh_url_to_repo": "ssh://jarka@localhost:2222/twitter/flight.git",
    "http_url_to_repo": "http://localhost:3000/twitter/flight.git",
    "web_url": "http://localhost:3000/twitter/flight",
    "readme_url": "http://localhost:3000/twitter/flight/-/blob/main/README.md",
    "avatar_url": null,
    "star_count": 0,
    "forks_count": 0,
    "last_activity_at": "2018-01-31T09:56:30.902Z"
  }
]
```

### Scope: `issues`

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/search?scope=issues&search=file"
```

Example response:

```json
[
  {
    "id": 83,
    "iid": 1,
    "project_id": 12,
    "title": "Add file",
    "description": "Add first file",
    "state": "opened",
    "created_at": "2018-01-24T06:02:15.514Z",
    "updated_at": "2018-02-06T12:36:23.263Z",
    "closed_at": null,
    "labels":[],
    "milestone": null,
    "assignees": [{
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    }],
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    },
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "discussion_locked": null,
    "web_url": "http://localhost:3000/h5bp/7bp/subgroup-prj/issues/1",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

NOTE:
The `assignee` column is deprecated. It is shown as a single-sized array `assignees` to conform to the GitLab EE API.

### Scope: `merge_requests`

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/search?scope=merge_requests&search=file"
```

Example response:

```json
[
  {
    "id": 56,
    "iid": 8,
    "project_id": 6,
    "title": "Add first file",
    "description": "This is a test MR to add file",
    "state": "opened",
    "created_at": "2018-01-22T14:21:50.830Z",
    "updated_at": "2018-02-06T12:40:33.295Z",
    "target_branch": "main",
    "source_branch": "jaja-test",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 5,
      "name": "Jacquelyn Kutch",
      "username": "abigail",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/3138c66095ee4bd11a508c2f7f7772da?s=80&d=identicon",
      "web_url": "http://localhost:3000/abigail"
    },
    "source_project_id": 6,
    "target_project_id": 6,
    "labels": [
      "ruby",
      "tests"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 13,
      "iid": 3,
      "project_id": 6,
      "title": "v2.0",
      "description": "Qui aut qui eos dolor beatae itaque tempore molestiae.",
      "state": "active",
      "created_at": "2017-09-05T07:58:29.099Z",
      "updated_at": "2017-09-05T07:58:29.099Z",
      "due_date": null,
      "start_date": null
    },
    "merge_when_pipeline_succeeds": false,
    "merge_status": "can_be_merged",
    "sha": "78765a2d5e0a43585945c58e61ba2f822e4d090b",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 0,
    "discussion_locked": null,
    "should_remove_source_branch": null,
    "force_remove_source_branch": true,
    "web_url": "http://localhost:3000/twitter/flight/merge_requests/8",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

### Scope: `milestones`

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/search?scope=milestones&search=release"
```

Example response:

```json
[
  {
    "id": 44,
    "iid": 1,
    "project_id": 12,
    "title": "next release",
    "description": "Next release milestone",
    "state": "active",
    "created_at": "2018-02-06T12:43:39.271Z",
    "updated_at": "2018-02-06T12:44:01.298Z",
    "due_date": "2018-04-18",
    "start_date": "2018-02-04"
  }
]
```

### Scope: `snippet_titles`

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/search?scope=snippet_titles&search=sample"
```

Example response:

```json
[
  {
    "id": 50,
    "title": "Sample file",
    "file_name": "file.rb",
    "description": "Simple ruby file",
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "updated_at": "2018-02-06T12:49:29.104Z",
    "created_at": "2017-11-28T08:20:18.071Z",
    "project_id": 9,
    "web_url": "http://localhost:3000/root/jira-test/snippets/50"
  }
]
```

### Scope: `users`

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/search?scope=users&search=doe"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://localhost/user1"
  }
]
```

### Scope: `wiki_blobs`

DETAILS:
**Tier:** Premium, Ultimate

This scope is available only when [advanced search is enabled](../user/search/advanced_search.md#enable-advanced-search).

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/search?scope=wiki_blobs&search=bye"
```

Example response:

```json

[
  {
    "basename": "home",
    "data": "hello\n\nand bye\n\nend",
    "path": "home.md",
    "filename": "home.md",
    "id": null,
    "ref": "main",
    "startline": 5,
    "project_id": 6,
    "group_id": null
  }
]
```

NOTE:
`filename` is deprecated in favor of `path`. Both return the full path of the file inside the repository, but in the future `filename` is intended to be only the filename and not the full path. For details, see [issue 34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521).

### Scope: `commits`

DETAILS:
**Tier:** Premium, Ultimate

This scope is available only when [advanced search is enabled](../user/search/advanced_search.md#enable-advanced-search).

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/search?scope=commits&search=bye"
```

Example response:

```json

[
  {
  "id": "4109c2d872d5fdb1ed057400d103766aaea97f98",
  "short_id": "4109c2d8",
  "title": "goodbye $.browser",
  "created_at": "2013-02-18T22:02:54.000Z",
  "parent_ids": [
    "59d05353ab575bcc2aa958fe1782e93297de64c9"
  ],
  "message": "goodbye $.browser\n",
  "author_name": "angus croll",
  "author_email": "anguscroll@gmail.com",
  "authored_date": "2013-02-18T22:02:54.000Z",
  "committer_name": "angus croll",
  "committer_email": "anguscroll@gmail.com",
  "committed_date": "2013-02-18T22:02:54.000Z",
  "project_id": 6
  }
]
```

### Scope: `blobs`

DETAILS:
**Tier:** Premium, Ultimate

This scope is available only when [advanced search is enabled](../user/search/advanced_search.md#enable-advanced-search).

The following filters are available for this scope:

- `filename`
- `path`
- `extension`

To use a filter, include it in your query. For example: `a query filename:some_name*`.

You may use wildcards (`*`) to use glob matching.

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/search?scope=blobs&search=installation"
```

Example response:

```json

[
  {
    "basename": "README",
    "data": "```\n\n## Installation\n\nQuick start using the [pre-built",
    "path": "README.md",
    "filename": "README.md",
    "id": null,
    "ref": "main",
    "startline": 46,
    "project_id": 6
  }
]
```

NOTE:
`filename` is deprecated in favor of `path`. Both return the full path of the file inside the repository, but in the future `filename` is intended to be only the filename and not the full path. For details, see [issue 34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521).

### Scope: `notes`

DETAILS:
**Tier:** Premium, Ultimate

This scope is available only when [advanced search is enabled](../user/search/advanced_search.md#enable-advanced-search).

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/search?scope=notes&search=maxime"
```

Example response:

```json
[
  {
    "id": 191,
    "body": "Harum maxime consequuntur et et deleniti assumenda facilis.",
    "attachment": null,
    "author": {
      "id": 23,
      "name": "User 1",
      "username": "user1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/111d68d06e2d317b5a59c2c6c5bad808?s=80&d=identicon",
      "web_url": "http://localhost:3000/user1"
    },
    "created_at": "2017-09-05T08:01:32.068Z",
    "updated_at": "2017-09-05T08:01:32.068Z",
    "system": false,
    "noteable_id": 22,
    "noteable_type": "Issue",
    "project_id": 6,
    "noteable_iid": 2
  }
]
```

## Group search API

Search for a [term](../user/search/_index.md) in the specified group.

If a user is not a member of a group and the group is private, a `GET` request on that group results in a `404 Not Found` status code.

```plaintext
GET /groups/:id/search
```

| Attribute | Type | Required | Description  |
| --------- | ---- | -------- | -------------|
| `id`                | integer or string   | Yes | The ID or [URL-encoded path of the group](rest/_index.md#namespaced-paths). |
| `scope`       | string   | Yes | The scope to search in. Values include `projects`, `issues`, `merge_requests`, `milestones`, and `users`. Additional scopes are `wiki_blobs`, `commits`, `blobs`, and `notes`. |
| `search`      | string   | Yes | The search term. |
| `confidential` | boolean   | No | Filter by confidentiality. Supports only `issues` scope; other scopes are ignored. |
| `order_by`    | string   | No | Allowed values are `created_at` only. If not set, results are sorted by `created_at` in descending order for basic search, or by the most relevant documents for advanced search.|
| `sort`    | string   | No | Allowed values are `asc` or `desc` only. If not set, results are sorted by `created_at` in descending order for basic search, or by the most relevant documents for advanced search.|
| `state`       | string   | No | Filter by state. Supports `issues` and `merge_requests` only; other scopes are ignored. |

The response depends on the requested scope.

### Scope: `projects`

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/3/search?scope=projects&search=flight"
```

Example response:

```json
[
  {
    "id": 6,
    "description": "Nobis sed ipsam vero quod cupiditate veritatis hic.",
    "name": "Flight",
    "name_with_namespace": "Twitter / Flight",
    "path": "flight",
    "path_with_namespace": "twitter/flight",
    "created_at": "2017-09-05T07:58:01.621Z",
    "default_branch": "main",
    "tag_list":[], //deprecated, use `topics` instead
    "topics":[],
    "ssh_url_to_repo": "ssh://jarka@localhost:2222/twitter/flight.git",
    "http_url_to_repo": "http://localhost:3000/twitter/flight.git",
    "web_url": "http://localhost:3000/twitter/flight",
    "readme_url": "http://localhost:3000/twitter/flight/-/blob/main/README.md",
    "avatar_url": null,
    "star_count": 0,
    "forks_count": 0,
    "last_activity_at": "2018-01-31T09:56:30.902Z"
  }
]
```

### Scope: `issues`

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/3/search?scope=issues&search=file"
```

Example response:

```json
[
  {
    "id": 83,
    "iid": 1,
    "project_id": 12,
    "title": "Add file",
    "description": "Add first file",
    "state": "opened",
    "created_at": "2018-01-24T06:02:15.514Z",
    "updated_at": "2018-02-06T12:36:23.263Z",
    "closed_at": null,
    "labels":[],
    "milestone": null,
    "assignees": [{
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    }],
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    },
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "discussion_locked": null,
    "web_url": "http://localhost:3000/h5bp/7bp/subgroup-prj/issues/1",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

NOTE:
`assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

### Scope: `merge_requests`

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/3/search?scope=merge_requests&search=file"
```

Example response:

```json
[
  {
    "id": 56,
    "iid": 8,
    "project_id": 6,
    "title": "Add first file",
    "description": "This is a test MR to add file",
    "state": "opened",
    "created_at": "2018-01-22T14:21:50.830Z",
    "updated_at": "2018-02-06T12:40:33.295Z",
    "target_branch": "main",
    "source_branch": "jaja-test",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 5,
      "name": "Jacquelyn Kutch",
      "username": "abigail",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/3138c66095ee4bd11a508c2f7f7772da?s=80&d=identicon",
      "web_url": "http://localhost:3000/abigail"
    },
    "source_project_id": 6,
    "target_project_id": 6,
    "labels": [
      "ruby",
      "tests"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 13,
      "iid": 3,
      "project_id": 6,
      "title": "v2.0",
      "description": "Qui aut qui eos dolor beatae itaque tempore molestiae.",
      "state": "active",
      "created_at": "2017-09-05T07:58:29.099Z",
      "updated_at": "2017-09-05T07:58:29.099Z",
      "due_date": null,
      "start_date": null
    },
    "merge_when_pipeline_succeeds": false,
    "merge_status": "can_be_merged",
    "sha": "78765a2d5e0a43585945c58e61ba2f822e4d090b",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 0,
    "discussion_locked": null,
    "should_remove_source_branch": null,
    "force_remove_source_branch": true,
    "web_url": "http://localhost:3000/twitter/flight/merge_requests/8",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

### Scope: `milestones`

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/3/search?scope=milestones&search=release"
```

Example response:

```json
[
  {
    "id": 44,
    "iid": 1,
    "project_id": 12,
    "title": "next release",
    "description": "Next release milestone",
    "state": "active",
    "created_at": "2018-02-06T12:43:39.271Z",
    "updated_at": "2018-02-06T12:44:01.298Z",
    "due_date": "2018-04-18",
    "start_date": "2018-02-04"
  }
]
```

### Scope: `users`

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/3/search?scope=users&search=doe"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://localhost/user1"
  }
]
```

### Scope: `wiki_blobs`

DETAILS:
**Tier:** Premium, Ultimate

This scope is available only when [advanced search is enabled](../user/search/advanced_search.md#enable-advanced-search).

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/6/search?scope=wiki_blobs&search=bye"
```

Example response:

```json

[
  {
    "basename": "home",
    "data": "hello\n\nand bye\n\nend",
    "path": "home.md",
    "filename": "home.md",
    "id": null,
    "ref": "main",
    "startline": 5,
    "project_id": 6,
    "group_id": 1
  }
]
```

NOTE:
`filename` is deprecated in favor of `path`. Both return the full path of the file inside the repository, but in the future `filename` is intended to be only the filename and not the full path. For details, see [issue 34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521).

### Scope: `commits`

DETAILS:
**Tier:** Premium, Ultimate

This scope is available only when [advanced search is enabled](../user/search/advanced_search.md#enable-advanced-search).

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/6/search?scope=commits&search=bye"
```

Example response:

```json

[
  {
  "id": "4109c2d872d5fdb1ed057400d103766aaea97f98",
  "short_id": "4109c2d8",
  "title": "goodbye $.browser",
  "created_at": "2013-02-18T22:02:54.000Z",
  "parent_ids": [
    "59d05353ab575bcc2aa958fe1782e93297de64c9"
  ],
  "message": "goodbye $.browser\n",
  "author_name": "angus croll",
  "author_email": "anguscroll@gmail.com",
  "authored_date": "2013-02-18T22:02:54.000Z",
  "committer_name": "angus croll",
  "committer_email": "anguscroll@gmail.com",
  "committed_date": "2013-02-18T22:02:54.000Z",
  "project_id": 6
  }
]
```

### Scope: `blobs`

DETAILS:
**Tier:** Premium, Ultimate

This scope is available only when [advanced search is enabled](../user/search/advanced_search.md#enable-advanced-search).

The following filters are available for this scope:

- `filename`
- `path`
- `extension`

To use a filter, include it in your query. For example: `a query filename:some_name*`.

You may use wildcards (`*`) to use glob matching.

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/6/search?scope=blobs&search=installation"
```

Example response:

```json

[
  {
    "basename": "README",
    "data": "```\n\n## Installation\n\nQuick start using the [pre-built",
    "path": "README.md",
    "filename": "README.md",
    "id": null,
    "ref": "main",
    "startline": 46,
    "project_id": 6
  }
]
```

NOTE:
`filename` is deprecated in favor of `path`. Both return the full path of the file inside the repository, but in the future `filename` is intended to be only the filename and not the full path. For details, see [issue 34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521).

### Scope: `notes`

DETAILS:
**Tier:** Premium, Ultimate

This scope is available only when [advanced search is enabled](../user/search/advanced_search.md#enable-advanced-search).

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/groups/6/search?scope=notes&search=maxime"
```

Example response:

```json
[
  {
    "id": 191,
    "body": "Harum maxime consequuntur et et deleniti assumenda facilis.",
    "attachment": null,
    "author": {
      "id": 23,
      "name": "User 1",
      "username": "user1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/111d68d06e2d317b5a59c2c6c5bad808?s=80&d=identicon",
      "web_url": "http://localhost:3000/user1"
    },
    "created_at": "2017-09-05T08:01:32.068Z",
    "updated_at": "2017-09-05T08:01:32.068Z",
    "system": false,
    "noteable_id": 22,
    "noteable_type": "Issue",
    "project_id": 6,
    "noteable_iid": 2
  }
]
```

## Project search API

Search for a [term](../user/search/_index.md) in the specified project.

If a user is not a member of a project and the project is private, a `GET` request on that project results in a `404` status code.

```plaintext
GET /projects/:id/search
```

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ------------|
| `id` | integer or string | Yes | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `scope`       | string   | Yes | The scope to search in. Values include `issues`, `merge_requests`, `milestones`, and `users`. Additional scopes are `wiki_blobs`, `commits`, `blobs`, and `notes`. |
| `search`      | string   | Yes | The search term. |
| `confidential` | boolean   | No | Filter by confidentiality. Supports `issues` scope; other scopes are ignored. |
| `ref`         | string   | No | The name of a repository branch or tag to search on. The project's default branch is used by default. Applicable only for scopes `blobs`, `commits`, and `wiki_blobs`. |
| `order_by`    | string   | No | Allowed values are `created_at` only. If not set, results are sorted by `created_at` in descending order for basic search, or by the most relevant documents for advanced search.|
| `sort`    | string   | No | Allowed values are `asc` or `desc` only. If not set, results are sorted by `created_at` in descending order for basic search, or by the most relevant documents for advanced search.|
| `state`       | string   | No | Filter by state. Supports the `issues` and `merge_requests` scopes; other scopes are ignored. |

The response depends on the requested scope.

### Scope: `issues`

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/12/search?scope=issues&search=file"
```

Example response:

```json
[
  {
    "id": 83,
    "iid": 1,
    "project_id": 12,
    "title": "Add file",
    "description": "Add first file",
    "state": "opened",
    "created_at": "2018-01-24T06:02:15.514Z",
    "updated_at": "2018-02-06T12:36:23.263Z",
    "closed_at": null,
    "labels":[],
    "milestone": null,
    "assignees": [{
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    }],
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 20,
      "name": "Ceola Deckow",
      "username": "sammy.collier",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/c23d85a4f50e0ea76ab739156c639231?s=80&d=identicon",
      "web_url": "http://localhost:3000/sammy.collier"
    },
    "user_notes_count": 0,
    "upvotes": 0,
    "downvotes": 0,
    "due_date": null,
    "confidential": false,
    "discussion_locked": null,
    "web_url": "http://localhost:3000/h5bp/7bp/subgroup-prj/issues/1",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

NOTE:
`assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

### Scope: `merge_requests`

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/6/search?scope=merge_requests&search=file"
```

Example response:

```json
[
  {
    "id": 56,
    "iid": 8,
    "project_id": 6,
    "title": "Add first file",
    "description": "This is a test MR to add file",
    "state": "opened",
    "created_at": "2018-01-22T14:21:50.830Z",
    "updated_at": "2018-02-06T12:40:33.295Z",
    "target_branch": "main",
    "source_branch": "jaja-test",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://localhost:3000/root"
    },
    "assignee": {
      "id": 5,
      "name": "Jacquelyn Kutch",
      "username": "abigail",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/3138c66095ee4bd11a508c2f7f7772da?s=80&d=identicon",
      "web_url": "http://localhost:3000/abigail"
    },
    "source_project_id": 6,
    "target_project_id": 6,
    "labels": [
      "ruby",
      "tests"
    ],
    "draft": false,
    "work_in_progress": false,
    "milestone": {
      "id": 13,
      "iid": 3,
      "project_id": 6,
      "title": "v2.0",
      "description": "Qui aut qui eos dolor beatae itaque tempore molestiae.",
      "state": "active",
      "created_at": "2017-09-05T07:58:29.099Z",
      "updated_at": "2017-09-05T07:58:29.099Z",
      "due_date": null,
      "start_date": null
    },
    "merge_when_pipeline_succeeds": false,
    "merge_status": "can_be_merged",
    "sha": "78765a2d5e0a43585945c58e61ba2f822e4d090b",
    "merge_commit_sha": null,
    "squash_commit_sha": null,
    "user_notes_count": 0,
    "discussion_locked": null,
    "should_remove_source_branch": null,
    "force_remove_source_branch": true,
    "web_url": "http://localhost:3000/twitter/flight/merge_requests/8",
    "time_stats": {
      "time_estimate": 0,
      "total_time_spent": 0,
      "human_time_estimate": null,
      "human_total_time_spent": null
    }
  }
]
```

### Scope: `milestones`

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/12/search?scope=milestones&search=release"
```

Example response:

```json
[
  {
    "id": 44,
    "iid": 1,
    "project_id": 12,
    "title": "next release",
    "description": "Next release milestone",
    "state": "active",
    "created_at": "2018-02-06T12:43:39.271Z",
    "updated_at": "2018-02-06T12:44:01.298Z",
    "due_date": "2018-04-18",
    "start_date": "2018-02-04"
  }
]
```

### Scope: `users`

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/6/search?scope=users&search=doe"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "John Doe1",
    "username": "user1",
    "state": "active",
    "avatar_url": "http://www.gravatar.com/avatar/c922747a93b40d1ea88262bf1aebee62?s=80&d=identicon",
    "web_url": "http://localhost/user1"
  }
]
```

### Scope: `wiki_blobs`

DETAILS:
**Tier:** Premium, Ultimate

This scope is available only when [advanced search is enabled](../user/search/advanced_search.md#enable-advanced-search).

The following filters are available for this scope:

- `filename`
- `path`
- `extension`

To use a filter, include it in your query. For example: `a query filename:some_name*`.
You may use wildcards (`*`) to use glob matching.

Wiki blobs searches are performed on both filenames and contents. Search
results:

- Found in filenames are displayed before results found in contents.
- May contain multiple matches for the same blob because the search string
  might be found in both the filename and content, or might appear multiple
  times in the content.

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/6/search?scope=wiki_blobs&search=bye"
```

Example response:

```json

[
  {
    "basename": "home",
    "data": "hello\n\nand bye\n\nend",
    "path": "home.md",
    "filename": "home.md",
    "id": null,
    "ref": "main",
    "startline": 5,
    "project_id": 6,
    "group_id": 1
  }
]
```

NOTE:
`filename` is deprecated in favor of `path`. Both return the full path of the file inside the repository, but in the future `filename` is intended to be only the filename and not the full path. For details, see [issue 34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521).

### Scope: `commits`

DETAILS:
**Tier:** Premium, Ultimate

This scope is available only when [advanced search is enabled](../user/search/advanced_search.md#enable-advanced-search).

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/6/search?scope=commits&search=bye"
```

Example response:

```json

[
  {
  "id": "4109c2d872d5fdb1ed057400d103766aaea97f98",
  "short_id": "4109c2d8",
  "title": "goodbye $.browser",
  "created_at": "2013-02-18T22:02:54.000Z",
  "parent_ids": [
    "59d05353ab575bcc2aa958fe1782e93297de64c9"
  ],
  "message": "goodbye $.browser\n",
  "author_name": "angus croll",
  "author_email": "anguscroll@gmail.com",
  "authored_date": "2013-02-18T22:02:54.000Z",
  "committer_name": "angus croll",
  "committer_email": "anguscroll@gmail.com",
  "committed_date": "2013-02-18T22:02:54.000Z",
  "project_id": 6
  }
]
```

### Scope: `blobs`

DETAILS:
**Tier:** Premium, Ultimate

This scope is available only when [advanced search is enabled](../user/search/advanced_search.md#enable-advanced-search).

The following filters are available for this scope:

- `filename`
- `path`
- `extension`

To use a filter, include it in your query. For example: `a query filename:some_name*`.
You may use wildcards (`*`) to use glob matching.

Blobs searches are performed on both filenames and contents. Search results:

- Found in filenames are displayed before results found in contents.
- May contain multiple matches for the same blob because the search string
  might be found in both the filename and content, or might appear multiple
  times in the content.

```shell
curl --request GET --header "PRIVATE-TOKEN: <your_access_token>" https://gitlab.example.com/api/v4/projects/6/search?scope=blobs&search=keyword%20filename:*.py
```

Example response:

```json

[
  {
    "basename": "README",
    "data": "```\n\n## Installation\n\nQuick start using the [pre-built",
    "path": "README.md",
    "filename": "README.md",
    "id": null,
    "ref": "main",
    "startline": 46,
    "project_id": 6
  }
]
```

NOTE:
`filename` is deprecated in favor of `path`. Both return the full path of the file inside the repository, but in the future `filename` is intended to be only the filename and not the full path. For details, see [issue 34521](https://gitlab.com/gitlab-org/gitlab/-/issues/34521).

### Scope: `notes`

DETAILS:
**Tier:** Premium, Ultimate

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/6/search?scope=notes&search=maxime"
```

Example response:

```json
[
  {
    "id": 191,
    "body": "Harum maxime consequuntur et et deleniti assumenda facilis.",
    "attachment": null,
    "author": {
      "id": 23,
      "name": "User 1",
      "username": "user1",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/111d68d06e2d317b5a59c2c6c5bad808?s=80&d=identicon",
      "web_url": "http://localhost:3000/user1"
    },
    "created_at": "2017-09-05T08:01:32.068Z",
    "updated_at": "2017-09-05T08:01:32.068Z",
    "system": false,
    "noteable_id": 22,
    "noteable_type": "Issue",
    "project_id": 6,
    "noteable_iid": 2
  }
]
```
