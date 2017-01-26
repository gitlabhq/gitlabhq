# Milestones

## List project milestones

Returns a list of project milestones.

```
GET /projects/:id/milestones
GET /projects/:id/milestones?iids=42
GET /projects/:id/milestones?iids[]=42&iids[]=43
GET /projects/:id/milestones?state=active
GET /projects/:id/milestones?state=closed
GET /projects/:id/milestones?search=version
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |

| `id` | integer/string | yes | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user |
| `iids` | Array[integer] | optional | Return only the milestones having the given `iids` |
| `state` | string | optional | Return only `active` or `closed` milestones` |
| `search` | string | optional | Return only milestones with a title or description matching the provided string |
| `order_by`| string  | no    | Return requests ordered by `created_at` or `updated_at` fields. Default is `created_at` |
| `sort`    | string  | no    | Return requests sorted in `asc` or `desc` order. Default is `desc`  |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v4/projects/5/milestones
```

Example Response:

```json
[
  {
    "id": 12,
    "iid": 3,
    "project_id": 16,
    "title": "10.0",
    "description": "Version",
    "due_date": "2013-11-29",
    "start_date": "2013-11-10",
    "state": "active",
    "updated_at": "2013-10-02T09:24:18Z",
    "created_at": "2013-10-02T09:24:18Z"
  }
]
```


## Get single milestone

Get a single project milestone.

```
GET /projects/:id/milestones/:milestone_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `milestone_id` (required) - The ID of the project's milestone

## Create new milestone

Creates a new project milestone.

```
POST /projects/:id/milestones
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `title` (required) - The title of an milestone
- `description` (optional) - The description of the milestone
- `due_date` (optional) - The due date of the milestone
- `start_date` (optional) - The start date of the milestone

## Edit milestone

Updates an existing project milestone.

```
PUT /projects/:id/milestones/:milestone_id
```

Parameters:

- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `milestone_id` (required) - The ID of a project milestone
- `title` (optional) - The title of a milestone
- `description` (optional) - The description of a milestone
- `due_date` (optional) - The due date of the milestone
- `start_date` (optional) - The start date of the milestone
- `state_event` (optional) - The state event of the milestone (close|activate)

## Get all issues assigned to a single milestone

Get all issues assigned to a single project milestone.

```
GET /projects/:id/milestones/:milestone_id/issues
```

Parameters:

<<<<<<< HEAD
- `id` (required) - The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) owned by the authenticated user
- `milestone_id` (required) - The ID of a project milestone

## Get all merge requests assigned to a single milestone

Gets all merge requests assigned to a single project milestone.
=======
| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a project |
| `milestone_id` | integer | yes | The ID of a project milestone |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/5/milestones/3/issues
```

## Get all merge requests assigned to a single project milestone

Get all merge requests assigned to a single project milestone.

```
GET /projects/:id/milestones/:milestone_id/merge_requests
```

Parameters:

| Attribute | Type | Required | Description |
| --------- | ---- | -------- | ----------- |
| `id` | integer | yes | The ID of a project |
| `milestone_id` | integer | yes | The ID of a project milestone |

```bash
curl --header "PRIVATE-TOKEN: 9koXpg98eAheJpvBs5tK" https://gitlab.example.com/api/v3/projects/5/milestones/3/merge_requests
```

Example response:

```json
[
  {
    "id": 40,
    "iid": 7,
    "project_id": 1,
    "title": "Laborum atque beatae qui aut magnam repudiandae.",
    "description": "Numquam consequuntur quos inventore laboriosam sint. Sit officiis ex nihil nisi consectetur veritatis recusandae rerum. Eligendi est laboriosam qui sed.",
    "state": "opened",
    "created_at": "2016-11-17T10:03:11.195Z",
    "updated_at": "2016-11-17T10:04:42.874Z",
    "target_branch": "100%branch",
    "source_branch": "feature",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "name": "User 2",
      "username": "user2",
      "id": 24,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/ab53a2911ddf9b4817ac01ddcd3d975f?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/user2"
    },
    "assignee": {
      "name": "Myrtie Smith DDS",
      "username": "arnold",
      "id": 13,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/97c594afcdf01e38ea8d1f3f1f82b33b?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/arnold"
    },
    "source_project_id": 1,
    "target_project_id": 1,
    "labels": [],
    "work_in_progress": false,
    "milestone": {
      "id": 38,
      "iid": 3,
      "project_id": 1,
      "title": "v2.0",
      "description": "Voluptatum quidem illo minima expedita.",
      "state": "closed",
      "created_at": "2016-11-17T10:02:00.843Z",
      "updated_at": "2016-11-17T10:02:00.843Z",
      "due_date": null,
      "start_date": null
    },
    "merge_when_build_succeeds": false,
    "merge_status": "unchecked",
    "sha": "0b4bc9a49b562e85de7cc9e834518ea6828729b9",
    "merge_commit_sha": null,
    "subscribed": true,
    "user_notes_count": 8,
    "should_remove_source_branch": null,
    "force_remove_source_branch": null,
    "web_url": "https://gitlab.example.com/gitlab-org/gitlab-test/merge_requests/7"
  },
  {
    "id": 35,
    "iid": 2,
    "project_id": 1,
    "title": "Autem sed et sequi provident mollitia at voluptatem minus.",
    "description": "Natus fugiat architecto necessitatibus dignissimos ullam est. Omnis nostrum animi nam et. Et commodi porro velit non odit quos doloremque dicta.",
    "state": "opened",
    "created_at": "2016-11-17T10:03:09.349Z",
    "updated_at": "2016-11-17T10:04:48.134Z",
    "target_branch": "conflict-too-large",
    "source_branch": "conflict_branch_a",
    "upvotes": 0,
    "downvotes": 0,
    "author": {
      "name": "Cameron Daugherty",
      "username": "ian",
      "id": 16,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/c460bc552d171d263f10ea1ed1118043?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/ian"
    },
    "assignee": {
      "name": "User 4",
      "username": "user4",
      "id": 26,
      "state": "active",
      "avatar_url": "http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon",
      "web_url": "https://gitlab.example.com/user4"
    },
    "source_project_id": 1,
    "target_project_id": 1,
    "labels": [],
    "work_in_progress": false,
    "milestone": {
      "id": 38,
      "iid": 3,
      "project_id": 1,
      "title": "v2.0",
      "description": "Voluptatum quidem illo minima expedita.",
      "state": "closed",
      "created_at": "2016-11-17T10:02:00.843Z",
      "updated_at": "2016-11-17T10:02:00.843Z",
      "due_date": null,
      "start_date": null
    },
    "merge_when_build_succeeds": false,
    "merge_status": "unchecked",
    "sha": "5b4bb08538b9249995b94aa69121365ba9d28082",
    "merge_commit_sha": null,
    "subscribed": true,
    "user_notes_count": 8,
    "should_remove_source_branch": null,
    "force_remove_source_branch": null,
    "web_url": "https://gitlab.example.com/gitlab-org/gitlab-test/merge_requests/2"
  }
]
```
