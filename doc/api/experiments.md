---
stage: Growth
group: Acquisition
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Experiments API
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com

{{< /details >}}

Use this API to interact with A/B experiments. This API is for internal use only.
It cannot be used with anonymous or unauthenticated users. For experiments
involving anonymous users, use the
[`glex_force` query parameter](https://gitlab.com/gitlab-org/ruby/gems/gitlab-experiment#forced-variant-assignment-qauat)
instead.

Prerequisites:

- You must be a [GitLab team member](https://gitlab.com/groups/gitlab-com/-/group_members).

## List all experiments

Lists all experiments on the GitLab instance. Each experiment has an `enabled` status that indicates
whether the experiment is enabled globally, or only in specific contexts.

```plaintext
GET /experiments
```

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/experiments"
```

Example response:

```json
[
  {
    "key": "code_quality_walkthrough",
    "definition": {
      "name": "code_quality_walkthrough",
      "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/58900",
      "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/327229",
      "milestone": "13.12",
      "type": "experiment",
      "group": "group::activation",
      "default_enabled": false
    },
    "current_status": {
      "state": "conditional",
      "gates": [
        {
          "key": "boolean",
          "value": false
        },
        {
          "key": "percentage_of_actors",
          "value": 25
        }
      ]
    }
  },
  {
    "key": "ci_runner_templates",
    "definition": {
      "name": "ci_runner_templates",
      "introduced_by_url": "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/58357",
      "rollout_issue_url": "https://gitlab.com/gitlab-org/gitlab/-/issues/326725",
      "milestone": "14.0",
      "type": "experiment",
      "group": "group::activation",
      "default_enabled": false
    },
    "current_status": {
      "state": "off",
      "gates": [
        {
          "key": "boolean",
          "value": false
        }
      ]
    }
  }
]
```

## Delete cached assignments

Removes all cached variant assignments for an experiment from the cache store. Use this endpoint to
clean up completed experiments whose code is removed from the codebase but whose cached assignments
remain.

```plaintext
DELETE /experiments/:name/cache
```

Supported attributes:

| Attribute | Type   | Required | Description |
|-----------|--------|----------|-------------|
| `name`    | string | Yes      | Cache key of the experiment to clear. |

If successful, returns [`204 No Content`](rest/troubleshooting.md#status-codes).

The request returns `204 No Content` even when no cached assignments exist for the given name.
The request returns `400 Bad Request` when the name references a cache key that is not an experiment.
The request returns `401 Unauthorized` when the request is not authenticated.
The request returns `403 Forbidden` when the user is not a GitLab team member.

> [!warning]
> The `name` value is used directly as the cache key. This endpoint clears any matching cache
> entry, even one that does not belong to a currently defined experiment. This behavior supports
> cleaning up orphaned experiments whose code is removed. Verify the name before you call this
> endpoint.

Example request:

```shell
curl --request DELETE \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/experiments/code_quality_walkthrough/cache"
```

## Experiment assignments

Use this endpoint to read experiment variant assignments
in the GLEX Redis cache. This is useful for backend-only experiments that run
outside of a request/response cycle, where the `glex_force` query parameter
is not available.

The experiment must declare `context_keys` in its experiment class in
`app/experiments`.

### Get the current assignment

Read the currently cached variant assignment for a given experiment and context.

```plaintext
GET /experiments/:experiment_name/assignments
```

Parameters:

| Attribute | Type | Required | Description |
|-----------|------|----------|-------------|
| `experiment_name` | string | Yes | Name of the experiment. |
| `context[user]` | string | No | Username for context. |
| `context[namespace]` | string | No | Full path of the namespace for context. |
| `context[project]` | string | No | Full path of the project for context. |

If you omit the `context[user]` parameter, the API uses the authenticated user.

If the experiment declares `actor` in its `context_keys`, the actor is resolved
from `context[user]`. There is no separate `context[actor]` parameter.

An experiment can declare multiple context keys, for example
`context_keys :user, :namespace`. In that case, pass every declared key.
Only the `user` and `actor` keys fall back to the authenticated user;
`namespace` and `project` must always be passed explicitly.

Example request for an experiment with a `user` context:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/experiments/my_experiment/assignments?context[user]=john-doe"
```

Example request for an experiment with a `namespace` context:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/experiments/my_experiment/assignments?context[namespace]=my-group"
```

Example request for an experiment that declares `context_keys :user, :namespace`:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/experiments/my_experiment/assignments?context[user]=john-doe&context[namespace]=my-group"
```

Example response:

```json
{
  "experiment": "my_experiment",
  "variant": "candidate",
  "context_key": "my_experiment:a1b2c3d4e5f6",
  "cached": true
}
```
