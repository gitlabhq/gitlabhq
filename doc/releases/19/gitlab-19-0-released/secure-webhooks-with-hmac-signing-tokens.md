---
title: Secure webhooks with HMAC signing tokens
stage: create
level: secondary
tier: [ Free, Premium, Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated, gitlab_dedicated_for_government ]
documentation_link: "../../../user/project/integrations/webhooks/#signing-tokens"
work_item: "https://gitlab.com/gitlab-org/gitlab/-/work_items/19367"
categories: [ Importers ]
weight: 110
---

The existing `X-Gitlab-Token` header sends a static secret in plain text,
making webhooks susceptible to interception and replay attacks.

You can now add a signing token to any webhook. GitLab uses
the signing token to compute an HMAC-SHA256 signature over:

- The unique webhook ID.
- The request timestamp.
- The webhook payload.

GitLab then sends the result in the `webhook-signature` header alongside
`webhook-id` and `webhook-timestamp` headers, following the
[Standard Webhooks](https://www.standardwebhooks.com/) specification.

You can recompute the signature to confirm requests genuinely came from GitLab
and that the payload has not been modified. By also validating the timestamp, you can reject replayed requests.

Thanks to [Van Anderson](https://gitlab.com/van.m.anderson) and
[Norman Debald](https://gitlab.com/Modjo85) for their community contributions!
