---
owning-stage: "~devops::verify"
description: 'GitLab Secrets Manager ADR 005: Non-hierarchical key structure for secrets in OpenBao'
---

# GitLab Secrets Manager ADR 005: Non-hierarchical key structure for secrets in OpenBao

## Context

In GitLab, we have a hierarchical structure for projects and their parent namespaces wherein names can be identical in certain parts of the paths. We want to ensure that there are no conflicts with secrets paths across the hierarchy and across all customers when we store then in OpenBao.

## Decision

While secrets are defined in a hierarchical fashion in the GitLab UI, the secret key paths are structured in a flat manner.

Consider the following example path of a project with nested namespaces:

- `gitlab-org/ci-cd/verify/test-project`
  - The secrets for the top-level group `gitlab-org` are stored under `kv-v2/data/namespaces/ci/<ID of gitlab-org>`
  - The secrets for the subgroup `verify` are stored under `kv-v2/data/namespaces/ci/<ID of verify>`
  - The secrets for the project `test-project` are stored under `kv-v2/data/projects/ci/<ID of test-project>`
  - Note the use of `ci/` prefix so that we can group different types of secrets.
