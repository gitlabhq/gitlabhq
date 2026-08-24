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

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/617465) in GitLab 19.4 [with a feature flag](../administration/feature_flags/_index.md) named `dependency_firewall_phase1`. Disabled by default.

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
