---
owning-stage: "~devops::verify"
description: 'GitLab Secrets Manager ADR 003: Implement Secrets Manager in Go'
---

# GitLab Secrets Manager ADR 003: Implement Secrets Manager in Go

Following [ADR-002](002_gcp_kms.md) highlighting the need to integrate with GCP
services, we do need to decide what tech stack is going to be used to build
GitLab Secrets Manager Service (GSMS).

## Context

At GitLab, we usually build satellite services around GitLab Rails in Go.
This is especially a good choice of technology for services that may heavily
leverage concurrency and caching, where cache could be invalidated / refreshed
asynchronously.

Go-based [GCP KMS](https://cloud.google.com/kms/docs/reference/libraries#client-libraries-usage-go)
client library also seems to expose a reliable interface to access KMS.

## Decision

Implement GitLab Secrets Manager Service in Go. Use
[labkit](https://gitlab.com/gitlab-org/labkit) as a minimalist library to
provide common functionality shared by satellite servicies.

## Consequences

The team that is going to own GitLab Secrets Manager feature will need to gain
more Go expertise.

## Alternatives

We considered implementing GitLab Secrets Manager Service in Ruby, but we
concluded that using Ruby will not allow us to build a service that will be
efficient enough.
