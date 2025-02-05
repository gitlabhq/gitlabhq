---
stage: Tenant Scale
group: Organizations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Topics API
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Interact with project topics using the REST API.

## List topics

Returns a list of project topics in the GitLab instance ordered by number of associated projects.

```plaintext
GET /topics
```

Supported attributes:

| Attribute          | Type    | Required               | Description |
| ------------------ | ------- | ---------------------- | ----------- |
| `page`             | integer | No | Page to retrieve. Defaults to `1`.                      |
| `per_page`         | integer | No | Number of records to return per page. Defaults to `20`. |
| `search`           | string  | No | Search topics against their `name`.                     |
| `without_projects` | boolean | No | Limit results to topics without assigned projects.      |

Example request:

```shell
curl "https://gitlab.example.com/api/v4/topics?search=git"
```

Example response:

```json
[
  {
    "id": 1,
    "name": "gitlab",
    "title": "GitLab",
    "description": "GitLab is an open source end-to-end software development platform with built-in version control, issue tracking, code review, CI/CD, and more.",
    "total_projects_count": 1000,
    "organization_id": 1,
    "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon"
  },
  {
    "id": 3,
    "name": "git",
    "title": "Git",
    "description": "Git is a free and open source distributed version control system designed to handle everything from small to very large projects with speed and efficiency.",
    "total_projects_count": 900,
    "organization_id": 1,
    "avatar_url": "http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon"
  },
  {
    "id": 2,
    "name": "git-lfs",
    "title": "Git LFS",
    "description": null,
    "total_projects_count": 300,
    "organization_id": 1,
    "avatar_url": null
  }
]
```

## Get a topic

Get a project topic by ID.

```plaintext
GET /topics/:id
```

Supported attributes:

| Attribute | Type    | Required               | Description         |
| --------- | ------- | ---------------------- | ------------------- |
| `id`      | integer | Yes | ID of project topic |

Example request:

```shell
curl "https://gitlab.example.com/api/v4/topics/1"
```

Example response:

```json
{
  "id": 1,
  "name": "gitlab",
  "title": "GitLab",
  "description": "GitLab is an open source end-to-end software development platform with built-in version control, issue tracking, code review, CI/CD, and more.",
  "total_projects_count": 1000,
  "organization_id": 1,
  "avatar_url": "http://www.gravatar.com/avatar/a0d477b3ea21970ce6ffcbb817b0b435?s=80&d=identicon"
}
```

## List projects assigned to a topic

Use the [Projects API](projects.md#list-all-projects) to list all projects assigned to a specific topic.

```plaintext
GET /projects?topic=<topic_name>
```

## Create a project topic

Create a new project topic. Only available to administrators.

```plaintext
POST /topics
```

Supported attributes:

| Attribute         | Type    | Required | Description                                                                                                                                                                                    |
|-------------------|---------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `name`            | string  | Yes      | Slug (name)                                                                                                                                                                                    |
| `title`           | string  | Yes      | Title                                                                                                                                                                                          |
| `avatar`          | file    | No       | Avatar                                                                                                                                                                                         |
| `description`     | string  | No       | Description                                                                                                                                                                                    |
| `organization_id` | integer | No       | The organization ID for the topic. Warning: this attribute is experimental and a subject to change in future. For more information on organizations, see [Organizations API](organizations.md) |

Example request:

```shell
curl --request POST \
     --data "name=topic1&title=Topic 1" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/topics"
```

Example response:

```json
{
  "id": 1,
  "name": "topic1",
  "title": "Topic 1",
  "description": null,
  "total_projects_count": 0,
  "organization_id": 1,
  "avatar_url": null
}
```

## Update a project topic

Update a project topic. Only available to administrators.

```plaintext
PUT /topics/:id
```

Supported attributes:

| Attribute     | Type    | Required | Description         |
|---------------|---------|----------|---------------------|
| `id`          | integer | Yes      | ID of project topic |
| `avatar`      | file    | No       | Avatar              |
| `description` | string  | No       | Description         |
| `name`        | string  | No       | Slug (name)         |
| `title`       | string  | No       | Title               |

Example request:

```shell
curl --request PUT \
     --data "name=topic1" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/topics/1"
```

Example response:

```json
{
  "id": 1,
  "name": "topic1",
  "title": "Topic 1",
  "description": null,
  "total_projects_count": 0,
  "organization_id": 1,
  "avatar_url": null
}
```

### Upload a topic avatar

To upload an avatar file from your file system, use the `--form` argument. This argument causes
cURL to post data using the header `Content-Type: multipart/form-data`. The
`file=` parameter must point to a file on your file system and be preceded by
`@`. For example:

```shell
curl --request PUT \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/topics/1" \
     --form "avatar=@/tmp/example.png"
```

### Remove a topic avatar

To remove a topic avatar, use a blank value for the `avatar` attribute.

Example request:

```shell
curl --request PUT \
     --data "avatar=" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/topics/1"
```

## Delete a project topic

You must be an administrator to delete a project topic.
When you delete a project topic, you also delete the topic assignment for projects.

```plaintext
DELETE /topics/:id
```

Supported attributes:

| Attribute | Type    | Required | Description         |
|-----------|---------|----------|---------------------|
| `id`      | integer | Yes      | ID of project topic |

Example request:

```shell
curl --request DELETE \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/topics/1"
```

## Merge topics

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/95501) in GitLab 15.4.

You must be an administrator to merge a source topic into a target topic.
When you merge topics, you delete the source topic and move all assigned projects to the target topic.

```plaintext
POST /topics/merge
```

Supported attributes:

| Attribute         | Type    | Required | Description                |
|-------------------|---------|----------|----------------------------|
| `source_topic_id` | integer | Yes      | ID of source project topic |
| `target_topic_id` | integer | Yes      | ID of target project topic |

NOTE:
The `source_topic_id` and `target_topic_id` must belong to the same organization.

Example request:

```shell
curl --request POST \
     --data "source_topic_id=2&target_topic_id=1" \
     --header "PRIVATE-TOKEN: <your_access_token>" \
     "https://gitlab.example.com/api/v4/topics/merge"
```

Example response:

```json
{
  "id": 1,
  "name": "topic1",
  "title": "Topic 1",
  "description": null,
  "total_projects_count": 0,
  "organization_id": 1,
  "avatar_url": null
}
```
