---
stage: Verify
group: Pipeline Security
info: "To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments"
---

# Project job token scope API **(FREE)**

NOTE:

- Every calls to the project token scope API must be authenticated, for example, with a personal access token.
- The authenticated user (personal access token) needs to have at least Maintainer role for the project.
- Depending on the usage, the personal access token requires read access (scope `read_api`) or read/write access (scope `api`) to the API.

## Get a project job token scope

Fetch CI_JOB_TOKEN access settings (job token scope) of a project.

```plaintext
GET /projects/:id/job_token_scope
```

Parameters

| Attribute | Type           | Required               | Description |
|-----------|----------------|------------------------|-------------|
| `id`      | integer/string | **{check-circle}** Yes | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |

Example of request

```shell
curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/job_token_scope"
```

Example of response

```json
{
  "inbound_enabled": true,
  "outbound_enabled": false
}
```

## Patch a project job token scope

Patch CI_JOB_TOKEN access settings of a project.

```plaintext
PATCH /projects/:id/job_token_scope
```

Parameters

| Attribute | Type           | Required                | Description |
|-----------|----------------|-------------------------|-------------|
| `id`      | integer/string | **{check-circle}** Yes  | ID or [URL-encoded path of the project](rest/index.md#namespaced-path-encoding) owned by the authenticated user. |
| `enabled` | boolean        | **{dotted-circle}** Yes | Indicates CI/CD job tokens generated in other projects have restricted access to this project. |

Example of request

```shell
curl --request PATCH \
  --url "https://gitlab.example.com/api/v4/projects/7/job_token_scope" \
  --header 'PRIVATE-TOKEN: <your_access_token>' \
  --header 'Content-Type: application/json' \
  --data '{ "enabled": false }'
```

Example of response

There is no response body.
