---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Composite Identity
---

For security reasons, you should use composite identity for any AI-generated activity on the GitLab platform that performs write actions.

Features that use Composite Identity:

- [GitLab Duo with Amazon Q](../../user/gitlab_duo/security.md)

## Prerequisites

To generate a composite identity token, you must have:

1. A [service account user](../../user/profile/service_accounts.md) who is the primary token owner.
   1. Can be instance-wide or group-scoped. Instance-wide accounts are typical for GitLab-built features; customer agentic flows should use tightly scoped accounts.
   1. Only users with specific roles can [create service accounts](../../user/profile/service_accounts.md#create-a-service-account). Plan where/how the account is created accordingly.
   1. Service accounts can be shared across features, but differentiating actions in the UI is harder if they share the same account (for example, the same user might appear to both create and review an MR).

1. Availability and licensing:
   1. Service accounts are available on Premium and Ultimate.
   1. As a result, composite identity requires GitLab Premium or Ultimate licenses.
1. The service account must have `composite_identity_enforced` set to `true`.
   1. This setting is not available in the service account creation UI and must be configured programmatically.
1. The OAuth application used for composite identity must enable a dynamic scope of `user:*`.
   1. This scope is not available in the OAuth application UI and must be configured programmatically.

## How to generate a composite identity token

Only OAuth tokens are supported.

1. Because a service account is a bot user that cannot sign in, the typical [authorization code flow](../../api/oauth2.md) (browser consent) does not work.
1. If integrating with third-party services:
   1. Manually generate an OAuth grant for the service account + OAuth app. See this [example for Amazon Q](https://gitlab.com/gitlab-org/gitlab/-/blob/3665a013d3eca00d50cbac4d4aec3053bd5ca9b5/ee/app/services/ai/amazon_q/amazon_q_trigger_service.rb#L135-142).
   1. Ensure the grant's scopes include the concrete dynamic scope for the human user who originated the AI request, formatted as `user:$ID` (for example, `user:123`). Include other scopes as needed (for example, `api`).
   1. Exchange the grant for an access token through `https://gitlab.example.com/oauth/toke`.
1. If not integrating with third-party services:
   1. You can skip the access grant and directly create an OAuth access token, ensuring the scopes include `user:$ID` and any required base scopes.
   1. Refresh the token through the standard `https://gitlab.example.com/oauth/token>` endpoint using `grant_type=refresh_token`.
1. The returned access token belongs to the service account but carries `user:$ID` in its scopes. It refreshes like a standard OAuth access token.

### Minimal, copy‑pasteable examples (Rails console and curl)

- Create an OAuth application (note this step is only needed if you want a bespoke OAuth app. The Duo Workflow default OAuth application and service account are created by calling `ee/app/services/ai/duo_workflows/onboarding_service.rb`):

```ruby
# Rails console
app = Authn::OauthApplication.new(
  name: "Composite Identity App",
  redirect_uri: Gitlab::Routing.url_helpers.root_url, # unused but cannot be nil
  scopes: ::Gitlab::Auth::AI_WORKFLOW_SCOPES + [::Gitlab::Auth::DYNAMIC_USER],
  trusted: false,
  confidential: false # public client (no secret required)
)
app.save!
```

- Create an authorization grant for a service account + human user:

```ruby
# Assuming you want to create a composite OAuth token for the Duo Workflow OAuth application and service account + root user in your GDK. 
org = Organizations::Organization.default_organization
user = User.first

oauth_token_service = Ai::DuoWorkflows::CreateCompositeOauthAccessTokenService.new(
  current_user: user,
  organization: org,
).execute
oauth_token_service.payload[:oauth_access_token].plaintext_token
```

## How authorization is evaluated

A request made with a composite identity token is authorized only if both are true:

- The service account has access to the resource.
- The human user identified by `user:$ID` in the token scopes has access to the resource.

## Request context and current_user

When a request includes a composite identity OAuth token, the Rails request context overrides `current_user` to the human user extracted from the `user:$ID` scope. While the token itself still belongs to the service account, the user who originated the request is considered the current user. This means:

- Any code that depends on `current_user` runs as the human user.
- You must update the code to invert composite identity to attribute actions to the service account.

### Attributing actions to the service account

Most features want the visible action (author/actor) to be the service account. In that case, you must update the code that is doing a write action so that it writes as the service account:

```ruby
service_account_user = Gitlab::Auth::Identity.invert_composite_identity(current_user)
```

- With composite identity, `invert_composite_identity` returns the primary (service account) user.
- Without composite identity, it returns `current_user` unchanged.

Use the returned `service_account_user` wherever you set authorship/actor (for example: notes, issues/MRs, commits, pipeline user context).

Reference: MR [!204010](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/204010)

## Verify your setup quickly

```shell
# Expect 200 only if BOTH the human and service account can read the project
curl --silent --show-error --fail --header "Authorization: Bearer <COMPOSITE_TOKEN>" \
  "https://gitlab.example.com/api/v4/projects/<NAMESPACE>%2F<PROJECT>"
```

Common outcomes:

- 403: one of the principals lacks permission.
- 404: resource not visible to either principal, or not found.

## Local/GDK testing tips

```ruby
# Rails console
service_account = User.find_by_username("service_account")
service_account.update!(composite_identity_enforced: true)
```

## Troubleshooting

- Dynamic scope rejected or ignored: ensure the OAuth app has `dynamic_scopes: "user:*"`.
- Token missing `user:$ID`: re-issue the grant/token with the concrete `user:$ID` in scopes.
- Platform action attributed to human, not service account: see [#attributing-actions-to-the-service-account]
- 422 on token exchange: redirect URI mismatch or expired grant.
- 403 on API requests: verify both principals have the required project/group permissions and that base scopes (for example, `api`) are present.
