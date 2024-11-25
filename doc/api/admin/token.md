---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Documentation for the REST API that exposes token information."
---

# Token information API

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed
**Status:** Experiment

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165157) in GitLab 17.5 [with a flag](../../administration/feature_flags.md) named `admin_agnostic_token_finder`. Disabled by default.
> - [Feed tokens added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/169821) in GitLab 17.6.
> - [OAuth application secrets added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172985) in GitLab 17.7.
> - [Cluster agent tokens added](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/172932) in GitLab 17.7.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

Administrators can use this API to retrieve information about arbitrary tokens. Unlike other API endpoints that expose token information, such as the
[Personal access token API](../personal_access_tokens.md#get-single-personal-access-token), this endpoint allows administrators to retrieve token information without knowing the type of
the token.

Prerequisites:

- You must be an administrator.

## Get Token Information

Returns information about a token.

Supported tokens:

- [Personal access tokens](../../user/profile/personal_access_tokens.md)
- [Deploy tokens](../../user/project/deploy_tokens/index.md)
- [Feed tokens](../../security/tokens/index.md#feed-token)
- [OAuth application secrets](../../integration/oauth_provider.md)
- [Cluster agent tokens](../../security/tokens/index.md#gitlab-cluster-agent-tokens)

```plaintext
POST /api/v4/admin/token
```

Supported attributes:

| Attribute    | Type    | Required | Description                      |
|--------------|---------|----------|----------------------------------|
| `token`      | string  | Yes      | Token that should be identified. |

If successful, returns [`200`](../rest/troubleshooting.md#status-codes) and information about the token.

Can return the following status codes:

- `200 OK`: Information about the token.
- `401 Unauthorized`: The user is not authorized.
- `403 Forbidden`: The user is not an administrator.
- `404 Not Found`: The token was not found.
- `422 Unprocessable`: The token type is not supported.

Example request:

```shell
curl --request POST \
  --url "https://gitlab.example.com/api/v4/admin/token" \
  --header "PRIVATE-TOKEN: <your_access_token>" \
  --header 'Content-Type: application/json' \
  --data '{"token": "glpat-<example-token>"}'
```

Example response:

```json
{
 "id": 1,
 "user_id": 70,
 "name": "project-access-token",
 "revoked": false,
 "expires_at": "2024-10-04",
 "created_at": "2024-09-04T07:19:18.652Z",
 "updated_at": "2024-09-04T07:19:18.652Z",
 "scopes": [
  "api",
  "read_api"
 ],
 "impersonation": false,
 "expire_notification_delivered": false,
 "last_used_at": null,
 "after_expiry_notification_delivered": false,
 "previous_personal_access_token_id": null,
 "advanced_scopes": null,
 "organization_id": 1
}
```
