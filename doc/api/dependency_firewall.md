---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: REST API to check and evaluate a project's Dependency Firewall.
title: Dependency Firewall API
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/work_items/23242) in GitLab 19.4 [with a feature flag](../administration/feature_flags/_index.md) named `dependency_firewall_phase1`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

Use this API to interact with the Dependency Firewall for a project.
The Dependency Firewall blocks packages that do not meet a project's security policies before
they are fetched.

## Retrieve status of Dependency Firewall for a project

Retrieves the status of Dependency Firewall for a specified project. Use this endpoint to
determine whether to skip the firewall for an entire run. Projects with the firewall turned off
return a successful response rather than `404 Not Found`, so you can tell them apart from
projects you cannot access.

This endpoint accepts a personal access token, project access token, group access token,
OAuth token, or [CI/CD job token](../ci/jobs/ci_job_token.md). Deploy tokens are not supported.
Unauthenticated requests are refused, including for public projects.

A CI/CD job token needs no particular fine-grained permission. What constrains it is the project
its job runs in: a job token can only check that project. A request for any other project is
refused with `403 Forbidden`, even when the target project allows the job's project in its
[inbound job token allowlist](../ci/jobs/ci_job_token.md), and regardless of which fine-grained
permissions that allowlist entry grants. One project's firewall status is not information
another project's pipeline needs.

Prerequisites:

- You must have permission to read the project.

```plaintext
GET /projects/:id/dependency_firewall/enablement
```

Supported attributes:

| Attribute | Type              | Required | Description |
| --------- | ----------------- | -------- | ----------- |
| `id`      | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute  | Type    | Description |
| ---------- | ------- | ----------- |
| `enabled`  | boolean | Whether the Dependency Firewall is enabled for the project. A single combined answer: the response does not say whether the license or the namespace setting produced it. |

Possible response codes:

| Status code | Description |
| ----------- | ----------- |
| `401`       | Unauthorized. The request did not include valid authentication. |
| `403`       | Forbidden. The credential is not permitted to use this endpoint: a CI/CD job token for any project other than the one its job runs in, or a fine-grained token without permission to read the project. A user who cannot read the project receives `404` instead. |
| `404`       | Not found. The meaning depends on which key the response body uses: `enabled`, `message`, or `error`. See the guidance after this table. |
| `429`       | Too many requests. You have exceeded the rate limit for this endpoint, which is scoped to the calling user. The limit is separate from the limit on other project endpoints. |

While the feature flag is off, the endpoint returns `404` rather than `200`, because the
endpoint is not generally available yet. A `404` response therefore means one of three things,
and a client tells them apart by which key the response body uses, not by the wording of the
text:

- A body with an `enabled` key, such as `{"enabled": false}`, means the feature flag is off for
  this project. The firewall is not active, so a client can skip it for the run.
- A body with an `error` key, such as `{"error":"404 Not Found"}`, means this endpoint does not
  exist on the instance. For example, the instance might run GitLab Community Edition, or a
  version released before this endpoint was added. A client should fall back to its previous
  behavior instead of reporting a configuration problem.
- A body with a `message` key means the endpoint exists and refused the request. The project
  either does not exist or you cannot read it. A client should report a configuration problem
  and must not treat the project as unprotected.

Do not key this decision on the message text. A caller whose project is unreadable gets
`{"message":"404 Project Not Found"}`, but a fine-grained token that lacks access to the project
gets `{"message":"404 Not Found"}`, which reads the same as the endpoint-missing case if you
compare only the wording.

Example request:

```shell
curl --request GET \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --url "https://gitlab.example.com/api/v4/projects/1/dependency_firewall/enablement"
```

Example response:

```json
{
  "enabled": true
}
```

To authenticate from a pipeline job, use a [CI/CD job token](../ci/jobs/ci_job_token.md) with
the `JOB-TOKEN` header:

```shell
curl --request GET \
  --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
  --url "https://gitlab.example.com/api/v4/projects/1/dependency_firewall/enablement"
```

## Evaluate a package against Dependency Firewall policies for a project

Evaluates a single package against the Dependency Firewall policies for a specified project.

This endpoint accepts a personal access token, project access token, group access token,
OAuth token, or [CI/CD job token](../ci/jobs/ci_job_token.md). A job token from a project
outside the target project's job token scope is refused with a `403 Forbidden` status code.
Deploy tokens are not supported.

Prerequisites:

- You must have at least the Reporter role for the project.
- You must have permission to read packages in the project.

```plaintext
POST /projects/:id/dependency_firewall/evaluate
```

Supported attributes:

| Attribute   | Type              | Required | Description |
|-------------|-------------------|----------|-------------|
| `id`        | integer or string | yes      | The ID or [URL-encoded path of the project](rest/_index.md#namespaced-paths). |
| `ecosystem` | string            | yes      | Package ecosystem. One of `maven`, `npm`, `pypi`, or `gem`. |
| `name`      | string            | yes      | Package name, maximum 255 characters. For `maven`, use the `groupId:artifactId` form, for example `com.example:trivial-lib`. For `pypi`, names are normalized according to PEP 503 before evaluation, so `Flask_Login` and `flask-login` are equivalent. |
| `version`   | string            | yes      | Package version, maximum 255 characters. |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following response
attributes:

| Attribute | Type   | Description |
|-----------|--------|-------------|
| `outcome` | string | Evaluation outcome. One of `allowed`, `warned`, or `blocked`. |
| `reason`  | string | Message describing why the package was warned or blocked. Names the matching policy. `null` when `outcome` is `allowed`. |

The `outcome` attribute has one of the following values:

- `allowed`: No policy rule matched the package. A project with the Dependency Firewall enabled
  but no policy linked to it always returns `allowed`. An `allowed` outcome is not an assertion
  that GitLab holds vulnerability or license data for the package. A package that is absent from
  the package metadata database is also allowed.
- `warned`: A policy rule matched the package, and the matching policy is in warn mode.
- `blocked`: A policy rule matched the package, and the matching policy is in enforce mode.

This endpoint can also return the following status codes:

| Status code | Code | Description |
|-------------|------|-------------|
| `400` | None | `name` or `version` is blank, or `ecosystem` is not one of the accepted values. |
| `401` | None | The request was not authenticated. |
| `403` | None | The authenticated user cannot read packages in the project, or the request used a job token from outside the project's job token scope. |
| `404` | None | The project does not exist, the authenticated user has no access to it, or the `dependency_firewall_phase1` feature flag is disabled. |
| `422` | `dependency_firewall_not_enforced` | The Dependency Firewall is not enabled for the project. |
| `429` | None | The rate limit for this endpoint was exceeded. The limit is scoped to the combination of project and user. |
| `503` | `dependency_firewall_evaluation_failed` | A package metadata lookup did not complete. Block the fetch. |

Example request:

```shell
curl --request POST \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/1/dependency_firewall/evaluate" \
  --data '{"ecosystem": "npm", "name": "lodash", "version": "4.17.15"}'
```

Example response:

```json
{
  "outcome": "blocked",
  "reason": "Package 'lodash' violates 'deny-mit' policy"
}
```

Example response for a project that has the Dependency Firewall enabled but no policy linked to it:

```json
{
  "outcome": "allowed",
  "reason": null
}
```

From a pipeline job, authenticate with a [CI/CD job token](../ci/jobs/ci_job_token.md):

```shell
curl --request POST \
  --header "JOB-TOKEN: ${CI_JOB_TOKEN}" \
  --header "Content-Type: application/json" \
  --url "https://gitlab.example.com/api/v4/projects/1/dependency_firewall/evaluate" \
  --data '{"ecosystem": "npm", "name": "lodash", "version": "4.17.15"}'
```
