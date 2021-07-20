---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Project iterations API **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/118742) in GitLab 13.5.
> - Moved to GitLab Premium in 13.9.

This page describes the project iterations API.
There's a separate [group iterations API](group_iterations.md) page.

As of GitLab 13.5, we don't have project-level iterations, but you can use this endpoint to fetch the iterations of the project's ancestor groups.

## List project iterations

Returns a list of project iterations.

```plaintext
GET /projects/:id/iterations
GET /projects/:id/iterations?state=opened
GET /projects/:id/iterations?state=closed
GET /projects/:id/iterations?title=1.0
GET /projects/:id/iterations?search=version
```

| Attribute           | Type    | Required | Description |
| ------------------- | ------- | -------- | ----------- |
| `state`             | string  | no       | 'Return `opened`, `upcoming`, `current (previously started)`, `closed`, or `all` iterations. Filtering by `started` state is deprecated starting with 14.1, please use `current` instead.' |
| `search`            | string  | no       | Return only iterations with a title matching the provided string.                              |
| `include_ancestors` | boolean | no       | Include iterations from parent group and its ancestors. Defaults to `true`.                    |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/iterations"
```

Example response:

```json
[
  {
    "id": 53,
    "iid": 13,
    "group_id": 5,
    "title": "Iteration II",
    "description": "Ipsum Lorem ipsum",
    "state": 2,
    "created_at": "2020-01-27T05:07:12.573Z",
    "updated_at": "2020-01-27T05:07:12.573Z",
    "due_date": "2020-02-01",
    "start_date": "2020-02-14",
    "web_url": "http://gitlab.example.com/groups/my-group/-/iterations/13"
  }
]
```
