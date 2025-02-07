---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Resource group API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can read more about [controlling the job concurrency with resource groups](../ci/resource_groups/_index.md).

## Get all resource groups for a project

```plaintext
GET /projects/:id/resource_groups
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer/string     | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/resource_groups"
```

Example of response

```json
[
  {
    "id": 3,
    "key": "production",
    "process_mode": "unordered",
    "created_at": "2021-09-01T08:04:59.650Z",
    "updated_at": "2021-09-01T08:04:59.650Z"
  }
]
```

## Get a specific resource group

```plaintext
GET /projects/:id/resource_groups/:key
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer/string     | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `key`     | string  | yes      | The key of the resource group |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/resource_groups/production"
```

Example of response

```json
{
  "id": 3,
  "key": "production",
  "process_mode": "unordered",
  "created_at": "2021-09-01T08:04:59.650Z",
  "updated_at": "2021-09-01T08:04:59.650Z"
}
```

## List upcoming jobs for a specific resource group

```plaintext
GET /projects/:id/resource_groups/:key/upcoming_jobs
```

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer/string     | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths) |
| `key`     | string  | yes      | The key of the resource group |

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/50/resource_groups/production/upcoming_jobs"
```

Example of response

```json
[
  {
    "id": 1154,
    "status": "waiting_for_resource",
    "stage": "deploy",
    "name": "deploy_to_production",
    "ref": "main",
    "tag": false,
    "coverage": null,
    "allow_failure": false,
    "created_at": "2022-09-28T09:57:04.590Z",
    "started_at": null,
    "finished_at": null,
    "duration": null,
    "queued_duration": null,
    "user": {
      "id": 1,
      "username": "john_smith",
      "name": "John Smith",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/2d691a4d0427ca8db6efc3924a6408ba?s=80\u0026d=identicon",
      "web_url": "http://localhost:3000/john_smith",
      "created_at": "2022-05-27T19:19:17.526Z",
      "bio": "",
      "location": null,
      "public_email": null,
      "skype": "",
      "linkedin": "",
      "twitter": "",
      "website_url": "",
      "organization": null,
      "job_title": "",
      "pronouns": null,
      "bot": false,
      "work_information": null,
      "followers": 0,
      "following": 0,
      "local_time": null
    },
    "commit": {
      "id": "3177f39064891bbbf5124b27850c339da331f02f",
      "short_id": "3177f390",
      "created_at": "2022-09-27T17:55:31.000+02:00",
      "parent_ids": [
        "18059e45a16eaaeaddf6fc0daf061481549a89df"
      ],
      "title": "List upcoming jobs",
      "message": "List upcoming jobs",
      "author_name": "Example User",
      "author_email": "user@example.com",
      "authored_date": "2022-09-27T17:55:31.000+02:00",
      "committer_name": "Example User",
      "committer_email": "user@example.com",
      "committed_date": "2022-09-27T17:55:31.000+02:00",
      "trailers": {},
      "web_url": "https://gitlab.example.com/test/gitlab/-/commit/3177f39064891bbbf5124b27850c339da331f02f"
    },
    "pipeline": {
      "id": 274,
      "iid": 9,
      "project_id": 50,
      "sha": "3177f39064891bbbf5124b27850c339da331f02f",
      "ref": "main",
      "status": "waiting_for_resource",
      "source": "web",
      "created_at": "2022-09-28T09:57:04.538Z",
      "updated_at": "2022-09-28T09:57:13.537Z",
      "web_url": "https://gitlab.example.com/test/gitlab/-/pipelines/274"
    },
    "web_url": "https://gitlab.example.com/test/gitlab/-/jobs/1154",
    "project": {
      "ci_job_token_scope_enabled": false
    }
  }
]
```

## Edit an existing resource group

Updates an existing resource group's properties.

It returns `200` if the resource group was successfully updated. In case of an error, a status code `400` is returned.

```plaintext
PUT /projects/:id/resource_groups/:key
```

| Attribute       | Type    | Required                          | Description                      |
| --------------- | ------- | --------------------------------- | -------------------------------  |
| `id`            | integer/string | yes                        | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths)            |
| `key`           | string  | yes                               | The key of the resource group |
| `process_mode`  | string  | no                                | The process mode of the resource group. One of `unordered`, `oldest_first` or `newest_first`. Read [process modes](../ci/resource_groups/_index.md#process-modes) for more information. |

```shell
curl --request PUT --data "process_mode=oldest_first" \
     --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/resource_groups/production"
```

Example response:

```json
{
  "id": 3,
  "key": "production",
  "process_mode": "oldest_first",
  "created_at": "2021-09-01T08:04:59.650Z",
  "updated_at": "2021-09-01T08:13:38.679Z"
}
```
