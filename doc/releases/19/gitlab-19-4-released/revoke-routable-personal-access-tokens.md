---
title: Automatic revocation for routable personal access tokens
tier: [ Ultimate ]
offering: [ gitlab_com, self_managed, gitlab_dedicated ]
stage: application_security_testing
documentation_link: "../../../user/application_security/secret_detection/automatic_response"
work_item: https://gitlab.com/gitlab-org/gitlab/-/work_items/623418
categories: [ Secret Detection ]
---

When secret detection finds a leaked GitLab personal access token in a public
project, automatic response revokes it. In GitLab versions earlier than
19.4, revocation used only one detection rule and revoked only the legacy token format.
Tokens created on GitLab 18.3 and later use the routable or versioned routable format.
GitLab detected and reported these tokens without revoking them.

In GitLab 19.4 and later, revocation recognizes all three GitLab personal access token detection rules:

- `gitlab_personal_access_token`
- `gitlab_personal_access_token_routable`
- `gitlab_personal_access_token_routable_versioned`

Revocation also covers findings from [GitLab Secret Scanning for Source Code](../../../user/application_security/secret_detection/gitlab_secret_scanner/_index.md) and the [Gitleaks-based analyzer](../../../user/application_security/secret_detection/pipeline/_index.md).
You do not need to change any configuration.
Instances with automatic response enabled get this wider coverage immediately.
