---
stage: Application Security Testing
group: Static Analysis
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Token Revocation API
---

The Token Revocation API is an externally-deployed HTTP API that interfaces with GitLab
to receive and revoke API tokens and other secrets detected by GitLab Secret Detection.
See the [high-level architecture](../../user/application_security/secret_detection/automatic_response.md)
to understand the Secret Detection post-processing and revocation flow.

GitLab.com uses the internally-maintained [Secret Revocation Service](https://gitlab.com/gitlab-com/gl-security/engineering-and-research/automation-team/secret-revocation-service)
(team-members only) as its Token Revocation API. For GitLab Self-Managed, you can create
your own API and configure GitLab to use it.

## Implement a Token Revocation API for self-managed

GitLab Self-Managed instances interested in using the revocation capabilities must:

- Implement and deploy your own Token Revocation API.
- Configure the GitLab instance to use the Token Revocation API.

Your service must:

- Match the API specification below.
- Provide two endpoints:
  - Fetching revocable token types.
  - Revoking leaked tokens.
- Be rate-limited and idempotent.

Requests to the documented endpoints are authenticated using API tokens passed in
the `Authorization` header. Request and response bodies, if present, are
expected to have the content type `application/json`.

All endpoints may return these responses:

- `401 Unauthorized`
- `405 Method Not Allowed`
- `500 Internal Server Error`

### `GET /v1/revocable_token_types`

Returns the valid `type` values for use in the `revoke_tokens` endpoint.

NOTE:
These values match the concatenation of [the `secrets` analyzer's](../../user/application_security/secret_detection/pipeline/_index.md)
[primary identifier](../integrations/secure.md#identifiers) by means
of concatenating the `primary_identifier.type` and `primary_identifier.value`.
For example, the value `gitleaks_rule_id_gitlab_personal_access_token` matches the following finding identifier:

```json
{"type": "gitleaks_rule_id", "name": "Gitleaks rule ID GitLab Personal Access Token", "value": "GitLab Personal Access Token"}
```

| Status Code | Description |
| ----- | --- |
| `200` | The response body contains the valid token `type` values. |

Example response body:

```json
{
    "types": ["gitleaks_rule_id_gitlab_personal_access_token"]
}
```

### `POST /v1/revoke_tokens`

Accepts a list of tokens to be revoked by the appropriate provider. Your service is responsible for communicating
with each provider to revoke the token.

| Status Code | Description |
| ----- | --- |
| `204` | All submitted tokens have been accepted for eventual revocation. |
| `400` | The request body is invalid or one of the submitted token types is not supported. The request should not be retried. |
| `429` | The provider has received too many requests. The request should be retried later. |

Example request body (space characters added to `token` value to prevent secret detection warnings):

```json
[{
    "type": "gitleaks_rule_id_gitlab_personal_access_token",
    "token": "glpat - 8GMtG8Mf4EnMJzmAWDU",
    "location": "https://example.com/some-repo/blob/abcdefghijklmnop/compromisedfile1.java"
},
{
    "type": "gitleaks_rule_id_gitlab_personal_access_token",
    "token": "glpat - tG84EGK33nMLLDE70zU",
    "location": "https://example.com/some-repo/blob/abcdefghijklmnop/compromisedfile2.java"
}]
```

### Configure GitLab to interface with the Token Revocation API

You must configure the following database settings in the GitLab instance:

| Setting | Type | Description |
| ------- | ---- | ----------- |
| `secret_detection_token_revocation_enabled` | Boolean | Whether automatic token revocation is enabled |
| `secret_detection_token_revocation_url` | String | A fully-qualified URL to the `/v1/revoke_tokens` endpoint of the Token Revocation API |
| `secret_detection_revocation_token_types_url` | String | A fully-qualified URL to the `/v1/revocable_token_types` endpoint of the Token Revocation API |
| `secret_detection_token_revocation_token` | String | A pre-shared token to authenticate requests to the Token Revocation API |

For example, to configure these values in the
[Rails console](../../administration/operations/rails_console.md#starting-a-rails-console-session):

```ruby
::Gitlab::CurrentSettings.update!(secret_detection_token_revocation_token: 'MYSECRETTOKEN')
::Gitlab::CurrentSettings.update!(secret_detection_token_revocation_url: 'https://gitlab.example.com/revocation_service/v1/revoke_tokens')
::Gitlab::CurrentSettings.update!(secret_detection_revocation_token_types_url: 'https://gitlab.example.com/revocation_service/v1/revocable_token_types')
::Gitlab::CurrentSettings.update!(secret_detection_token_revocation_enabled: true)
```

After you configure these values, the Token Revocation API will be called according to the
[high-level architecture](../../user/application_security/secret_detection/automatic_response.md#high-level-architecture)
diagram.
