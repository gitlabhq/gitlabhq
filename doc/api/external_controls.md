---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: External controls API
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use the external controls API to set the status of a check that uses an external service.

You can configure external controls with periodic ping functionality. When ping is enabled (default), GitLab automatically resets the control status to `pending` every 12 hours. When ping is disabled, the control status is updated only through API calls.

## Set status of an external control

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/13658) in GitLab 17.11.

{{< /history >}}

For a single external control, use the API to inform GitLab that a control has passed or failed a check by an external service.

Prerequisites

- Must use HMAC, Timestamp, and Nonce authentication for security.

```plaintext
PATCH /api/v4/projects/:id/compliance_external_controls/:external_control_id/status
```

HTTP Headers:

| Header                |  Type   | Required | Description                                                                                   |
| --------------------- | ------- | -------- | --------------------------------------------------------------------------------------------- |
| `X-Gitlab-Timestamp`  | string  | yes      | Current Unix timestamp.                                                                       |
| `X-Gitlab-Nonce`      | string  | yes      | Random string or token to prevent replay attacks.                                             |
| `X-Gitlab-Hmac-Sha256`| string  | yes      | HMAC-SHA256 signature of the request.                                                         |

Supported attributes:

| Attribute                | Type    | Required | Description                                                                                       |
| ------------------------ | ------- | -------- |---------------------------------------------------------------------------------------------------|
| `id`                     | integer | yes      | ID of a project.                                                                                  |
| `external_control_id`    | integer | yes      | ID of an external control.                                                                        |
| `status`                 | string  | yes      | Set to `pass` to mark the control as passed, or `fail` to fail it.                                |

If successful, returns [`200 OK`](rest/troubleshooting.md#status-codes) and the following
response attributes:

| Attribute                | Type     | Description                                   |
|--------------------------|----------|-----------------------------------------------|
| `status`                 | string   | The status that has been set for the control. |

Example request:

```shell
curl --request PATCH \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header "X-Gitlab-Timestamp: <X-Gitlab-Timestamp>" \
  --header "X-Gitlab-Nonce: <X-Gitlab-Nonce>" \
  --header "X-Gitlab-Hmac-Sha256: <X-Gitlab-Hmac-Sha256>" \
  --header "Content-Type: application/json" \
  --data '{"status": "pass"}' \
  --url "https://gitlab.example.com/api/v4/projects/<id>/compliance_external_controls/<external_control_id>/status"
```

Example response:

```json
{
    "status":"pass"
}
```

## Related topics

- [Compliance frameworks](../user/compliance/compliance_frameworks/_index.md)
