---
owning-stage: "~sec::govern"
description: 'GitLab Secrets Manager ADR 006: Use AppRole authentication method between Rails and OpenBao'
---

# GitLab Secrets Manager ADR 006: Use AppRole authentication method between Rails and OpenBao

## Context

Given GitLab Rails acts as a facade over OpenBao, it directly communicates with the OpenBao API on behalf of users. This means the GitLab Rails component will be granted access to read and write secrets and related configuration data for all projects and organizations to and from OpenBao. We must ensure that every request made by Rails to OpenBao is securely authenticated while staying performant.

## Authentication options

We evaluated 2 OpenBao authentication methods for GitLab Rails:

1. [JWT auth method](https://openbao.org/docs/auth/jwt/)
   - This is similar to how Runner authenticates with OpenBao when fetching secrets in a CI job. In every request, Rails needs to generate an ID token to authenticate with OpenBao.
1. [AppRole auth method](https://openbao.org/docs/auth/approle/)
   - Rails authenticates with OpenBao by providing a Role ID and a Secret ID which are already predefined.

## Decision

With performance in mind, avoiding the extra steps that need to happen if Rails were to authenticate via JWT in each request, we decided to go with the AppRole authentication method.

## Consequences

GitLab Rails is considered trusted environment, thus granting it access to manipulate secrets and related configuration across all organizations and projects in GitLab. Extra caution is needed to ensure that the secret ID for the role is protected and will never leak. Fortunately, AppRole usage best practices are [documented](https://developer.hashicorp.com/vault/tutorials/auth-methods/approle-best-practices).
