---
stage: Plan
group: Project Management
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Resource iteration events API **(STARTER)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/40850) in [GitLab Starter](https://about.gitlab.com/pricing/) 13.4.
> - It's [deployed behind a feature flag](../user/feature_flags.md), enabled by default.
> - It's enabled on GitLab.com.
> - It's recommended for production use.
> - For GitLab self-managed instances, GitLab administrators can opt to [disable it](#enable-or-disable-iterations-events-tracking).

NOTE: **Note:**
This feature might not be available to you. Check the **version history** note above for details.

Resource iteration events keep track of what happens to GitLab [issues](../user/project/issues/).

Use them to track which iteration was set, who did it, and when it happened.

## Issues

### List project issue iteration events

Gets a list of all iteration events for a single issue.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_iteration_events
```

| Attribute   | Type           | Required | Description                                                                     |
| ----------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`        | integer/string | yes      | The ID or [URL-encoded path of the project](README.md#namespaced-path-encoding) |
| `issue_iid` | integer        | yes      | The IID of an issue                                                             |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_iteration_events"
```

Example response:

```json
[
  {
    "id": 142,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-20T13:38:20.077Z",
    "resource_type": "Issue",
    "resource_id": 253,
    "iteration":   {
      "id": 50,
      "iid": 9,
      "group_id": 5,
      "title": "Iteration I",
      "description": "Ipsum Lorem",
      "state": 1,
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null
    },  
    "action": "add"
  },
  {
    "id": 143,
    "user": {
      "id": 1,
      "name": "Administrator",
      "username": "root",
      "state": "active",
      "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
      "web_url": "http://gitlab.example.com/root"
    },
    "created_at": "2018-08-21T14:38:20.077Z",
    "resource_type": "Issue",
    "resource_id": 253,
    "iteration":   {
      "id": 53,
      "iid": 13,
      "group_id": 5,
      "title": "Iteration II",
      "description": "Ipsum Lorem ipsum",
      "state": 2,
      "created_at": "2020-01-27T05:07:12.573Z",
      "updated_at": "2020-01-27T05:07:12.573Z",
      "due_date": null,
      "start_date": null
    },
    "action": "remove"
  }
]
```

### Get single issue iteration event

Returns a single iteration event for a specific project issue.

```plaintext
GET /projects/:id/issues/:issue_iid/resource_iteration_events/:resource_iteration_event_id
```

Parameters:

| Attribute                     | Type           | Required | Description                                                                     |
| ----------------------------- | -------------- | -------- | ------------------------------------------------------------------------------- |
| `id`                          | integer/string | yes      | The ID or [URL-encoded path](README.md#namespaced-path-encoding) of the project |
| `issue_iid`                   | integer        | yes      | The IID of an issue                                                             |
| `resource_iteration_event_id` | integer        | yes      | The ID of an iteration event                                                     |

Example request:

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/5/issues/11/resource_iteration_events/143"
```

Example response:

```json
{
  "id": 143,
  "user": {
    "id": 1,
    "name": "Administrator",
    "username": "root",
    "state": "active",
    "avatar_url": "https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon",
    "web_url": "http://gitlab.example.com/root"
  },
  "created_at": "2018-08-21T14:38:20.077Z",
  "resource_type": "Issue",
  "resource_id": 253,
  "iteration":   {
    "id": 53,
    "iid": 13,
    "group_id": 5,
    "title": "Iteration II",
    "description": "Ipsum Lorem ipsum",
    "state": 2,
    "created_at": "2020-01-27T05:07:12.573Z",
    "updated_at": "2020-01-27T05:07:12.573Z",
    "due_date": null,
    "start_date": null
  },
  "action": "remove"
}
```

### Enable or disable iterations events tracking **(STARTER)**

Iterations events tracking is under development but ready for production use.
It is deployed behind a feature flag that is **enabled by default**.
[GitLab administrators with access to the GitLab Rails console](../administration/feature_flags.md)
can opt to disable it.

To enable it:

```ruby
Feature.enable(:track_iteration_change_events)
```

To disable it:

```ruby
Feature.disable(:track_iteration_change_events)
```
