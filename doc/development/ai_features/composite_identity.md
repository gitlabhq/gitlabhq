---
stage: AI-powered
group: AI Framework
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Composite Identity
---

GitLab Duo with Amazon Q uses a [composite identity](../../user/gitlab_duo/security.md)
to authenticate requests.

For security reasons, you should use composite identity for any
AI-generated activity on the GitLab platform that performs write actions.

## Prerequisites

To generate a composite identity token, you must have:

1. A [service account user](../../user/profile/service_accounts.md) who can be the
   primary token owner for the composite identity token.
1. Because service accounts
   are only available on Premium and Ultimate instances, composite identity
   only works on EE GitLab instances.
1. The service account user must have the `composite_identity_enforced` boolean
   attribute set to `true`.
1. The OAuth application associated with the composite token must have a
   [dynamic scope](https://github.com/doorkeeper-gem/doorkeeper/pull/1739) of
   `user:*`. This scope is not available on the OAuth application web UI. As a
   result, the OAuth application must be created programmatically.

## How to generate a composite identity token

After you have met the requirements above, follow these steps to generate a
composite identity token. Only OAuth tokens are supported at present.

1. Because a service account is a bot user that cannot sign in, the typical
   [authorization code flow](../../api/oauth2.md), which asks the user to
   authorize access to their account in the browser, does not work.
1. If you are integrating with 3rd party services:
   1. Manually generate an OAuth grant for the service account + OAuth app.
      [Example](https://gitlab.com/gitlab-org/gitlab/-/blob/3665a013d3eca00d50cbac4d4aec3053bd5ca9b5/ee/app/services/ai/amazon_q/amazon_q_trigger_service.rb#L135-142)
      of how we do this for Amazon Q
      Ensure that the grant's scopes the `id` of the human user who
      originated the AI request.
   1. The OAuth grant can be exchange for an OAuth access token using the standard
      method of making a request to `'https://gitlab.example.com/oauth/token'`.
1. If you are not integrating with 3rd party services:
   1. You can skip the access grant and manually generate an OAuth access token
      Ensure that the token's scopes contains the `id` of the human user who
      originated the AI request.
   1. The OAuth access token can be refreshed using the standard method of
      making a request to `'https://gitlab.example.com/oauth/token'`.
1. The returned access token belongs to the service account but has `user:$ID`
   in the scopes. The token can be refreshed like a standard OAuth access token.

Any API requests made with composite identity token are automatically authorized
as composite identity requests. As a result, both the service account user and
the human user whose `id` is in the token scopes must have access to the
resource.
