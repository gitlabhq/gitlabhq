# Search API

[Introduced][ce-41763] in GitLab 10.5

Every API call to search must be authenticated.

## Global Search API

Search globally across the GitLab instance.

```
GET /search
```

| Attribute     | Type     | Required   | Description            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `scope`       | string   | yes        | The scope to search in                |
| `search`      | string   | yes        | The search query  |

Search the expression within the specified scope. Currently these scopes are supported: projects, issues, merge_requests, milestones, snippet_titles, snippet_blobs.

If Elasticsearch is enabled additional scopes available are blobs, wiki_blobs and commits. Find more about [the feature](../integration/elasticsearch.md).

The response depends on the requested scope.

### Scope: projects

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/search?scope=projects&search=flight
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
    "default_branch": "master",
    "tag_list":[],
    "ssh_url_to_repo": "ssh://jarka@localhost:2222/twitter/flight.git",
    "http_url_to_repo": "http://localhost:3000/twitter/flight.git",
    "web_url": "http://localhost:3000/twitter/flight",
    "avatar_url": null,
    "star_count": 0,
    "forks_count": 0,
    "last_activity_at": "2018-01-31T09:56:30.902Z"
  }
]
```

### Scope: issues

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/search?scope=issues&search=file
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

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

### Scope: merge_requests

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/search?scope=merge_requests&search=file
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
    "target_branch": "master",
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

### Scope: milestones

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/search?scope=milestones&search=release
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

### Scope: snippet_titles

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/search?scope=snippet_titles&search=sample
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

### Scope: snippet_blobs

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/search?scope=snippet_blos&search=test
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

### Scope: wiki_blobs

This scope is available only if [Elasticsearch](../integration/elasticsearch.md) is enabled.

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/search?scope=wiki_blobs&search=bye
```

Example response:

```json

[
  {
    "basename": "home",
    "data": "hello\n\nand bye\n\nend",
    "filename": "home.md",
    "id": null,
    "ref": "master",
    "startline": 5,
    "project_id": 6
  }
]
```

### Scope: commits

This scope is available only if [Elasticsearch](../integration/elasticsearch.md) is enabled.

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/search?scope=commits&search=bye
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

### Scope: blobs

This scope is available only if [Elasticsearch](../integration/elasticsearch.md) is enabled.

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/search?scope=blobs&search=installation
```

Example response:

```json

[
  {
    "basename": "README",
    "data": "```\n\n## Installation\n\nQuick start using the [pre-built",
    "filename": "README.md",
    "id": null,
    "ref": "master",
    "startline": 46,
    "project_id": 6
  }
]
```


## Group Search API

Search within the specified group.

If a user is not a member of a group and the group is private, a `GET` request on that group will result to a `404` status code.

```
GET /groups/:id/search
```

| Attribute     | Type     | Required   | Description            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the group](README.md#namespaced-path-encoding) owned by the authenticated user                |
| `scope`       | string   | yes        | The scope to search in                |
| `search`      | string   | yes        | The search query  |

Search the expression within the specified scope. Currently these scopes are supported: projects, issues, merge_requests, milestones.

If Elasticsearch is enabled additional scopes available are blobs, wiki_blobs and commits. Find more about [the feature](../integration/elasticsearch.md).

The response depends on the requested scope.

### Scope: projects

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/3/search?scope=projects&search=flight
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
    "default_branch": "master",
    "tag_list":[],
    "ssh_url_to_repo": "ssh://jarka@localhost:2222/twitter/flight.git",
    "http_url_to_repo": "http://localhost:3000/twitter/flight.git",
    "web_url": "http://localhost:3000/twitter/flight",
    "avatar_url": null,
    "star_count": 0,
    "forks_count": 0,
    "last_activity_at": "2018-01-31T09:56:30.902Z"
  }
]
```

### Scope: issues

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/3/search?scope=issues&search=file
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

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

### Scope: merge_requests

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/3/search?scope=merge_requests&search=file
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
    "target_branch": "master",
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

### Scope: milestones

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/3/search?scope=milestones&search=release
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

### Scope: wiki_blobs

This scope is available only if [Elasticsearch](../integration/elasticsearch.md) is enabled.

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/6/search?scope=wiki_blobs&search=bye
```

Example response:

```json

[
  {
    "basename": "home",
    "data": "hello\n\nand bye\n\nend",
    "filename": "home.md",
    "id": null,
    "ref": "master",
    "startline": 5,
    "project_id": 6
  }
]
```

### Scope: commits

This scope is available only if [Elasticsearch](../integration/elasticsearch.md) is enabled.

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/6/search?scope=commits&search=bye
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

### Scope: blobs

This scope is available only if [Elasticsearch](../integration/elasticsearch.md) is enabled.

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/groups/6/search?scope=blobs&search=installation
```

Example response:

```json

[
  {
    "basename": "README",
    "data": "```\n\n## Installation\n\nQuick start using the [pre-built",
    "filename": "README.md",
    "id": null,
    "ref": "master",
    "startline": 46,
    "project_id": 6
  }
]
```

## Project Search API

Search within the specified project.

If a user is not a member of a project and the project is private, a `GET` request on that project will result to a `404` status code.

```
GET /projects/:id/search
```

| Attribute     | Type     | Required   | Description            |
| ------------------- | ---------------- | ---------- | ---------------------------------------------------------------------------------------|
| `id`                | integer/string   | yes        | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user                |
| `scope`       | string   | yes        | The scope to search in                |
| `search`      | string   | yes        | The search query  |

Search the expression within the specified scope. Currently these scopes are supported: issues, merge_requests, milestones, notes, wiki_blobs, commits, blobs.

The response depends on the requested scope.


### Scope: issues

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/12/search?scope=issues&search=file
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

**Note**: `assignee` column is deprecated, now we show it as a single-sized array `assignees` to conform to the GitLab EE API.

### Scope: merge_requests

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/6/search?scope=merge_requests&search=file
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
    "target_branch": "master",
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

### Scope: milestones

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/12/search?scope=milestones&search=release
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

### Scope: notes

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/6/search?scope=notes&search=maxime
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
    "noteable_iid": 2
  }
]
```

### Scope: wiki_blobs

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/6/search?scope=wiki_blobs&search=bye
```

Example response:

```json

[
  {
    "basename": "home",
    "data": "hello\n\nand bye\n\nend",
    "filename": "home.md",
    "id": null,
    "ref": "master",
    "startline": 5,
    "project_id": 6
  }
]
```

### Scope: commits

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/6/search?scope=commits&search=bye
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

### Scope: blobs

```bash
curl --request GET --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/6/search?scope=blobs&search=installation
```

Example response:

```json

[
  {
    "basename": "README",
    "data": "```\n\n## Installation\n\nQuick start using the [pre-built",
    "filename": "README.md",
    "id": null,
    "ref": "master",
    "startline": 46,
    "project_id": 6
  }
]
```

[ce-41763]: https://gitlab.com/gitlab-org/gitlab-ce/issues/41763
