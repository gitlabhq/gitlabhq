---
owning-stage: "~devops::verify"
description: 'GitLab Secrets Manager ADR 004: Sateless Key Management Service'
---

# GitLab Secrets Manager ADR 004: Stateless Key Management Service

In [ADR-002](002_gcp_kms.md) we decided that we want to use Google's Cloud Key
Management Service to store private encryption keys. This will allow us to meet
various compliance requirements easier.

In this ADR we are going to describe the desired architecture of GitLab Secrets
Management Service, making it a stateless service, that is not connected to a
persistent datastore, other than an ephemeral local storage.

## Context

## Decision

Make GitLab Secrets Management Service a stateless application, not being
connected to a global data storage, like a relational or NoSQL database.

We are only going to support local block storage, presumably only for caching
purposes.

In order to manage decryption cost wisely, we would need to implement
multi-tier protection layers, and in-memory, per-instance,
[symmetric decryption key](001_envelop_encryption.md) caching, with cache TTL
depending on the protection tier. A hardware or software key can be used in
Google's Cloud KMS, depending on the tier too.

## Consequences

1. All private keys are going to be stored in Google's Cloud KMS.
1. Multi-tier protection will be implemented, with higher tries offering more protection.
1. Protection tier will be defined on per-organization level on the GitLab Rails Service side.
1. Depending on the protection level used, symmetric decryption keys can be in-memory cached.
1. The symmetric key's cache must not be valid for more than 24 hours..
1. The highest protection tier will use Hardware Security Module and no caching.
1. The GitLab Secrets Management Service will not store access-control metadata.
1. Identity de-multiplexing will happen on GitLab Rails Service side.
1. Decryption request will be signed by an organization's public key.
1. The service will verify decryption requestor's identity by checking the signature.

## Alternatives

We considered using a relational database, or a NoSQL database, both
self-managed and managed by a Cloud Provider, but concluded that this would add
a lot of complexity and would weaken the security posture of the service.
