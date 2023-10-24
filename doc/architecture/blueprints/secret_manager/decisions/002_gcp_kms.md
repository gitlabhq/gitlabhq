---
owning-stage: "~devops::verify"
description: 'GitLab Secrets Manager ADR 002: Use GCP Key Management Service'
---

# GitLab Secrets Manager ADR 002: Use GCP Key Management Service

## Context

Following from [ADR 001: Use envelope encryption](001_envelop_encryption.md), we need to find a solution to securely
store asymmetric keys belonging to each vault.

## Decision

We decided to rely on Google CLoud Platform (GCP) Key Management Service (KMS) to manage the asymmetric keys
used by the GitLab Secrets Manager vaults.

Using GCP provides a few advantages:

1. Avoid implementing our own secure storage of cryptographic keys.
1. Support for Hardware Security Modules (HSM).

```mermaid
sequenceDiagram
    participant A as Client
    participant B as GitLab Rails
    participant C as GitLab Secrets Service
    participant D as GCP Key Management Service

    Note over B,D: Initialize vault for project/group/organization

    B->>C: Initialize vault - create key pair

    Note over D: Incurs cost per key
    C->>D: Create new asymmetric key
    D->>C: Returns public key
    C->>B: Returns vault public key
    B->>B: Stores vault public key

    Note over A,C: Creating a new secret

    A->>B: Create new secret
    B->>B: Generate new symmetric data key
    B->>B: Encrypts secret with data key
    B->>B: Encrypts data key with vault public key
    B->>B: Stores envelope (encrypted secret + encrypted data key)
    B-->>B: Discards plain-text data key
    B->>A: Success

    Note over A,D: Retrieving a secret

    A->>B: Get secret
    B->>B: Retrieves envelope (encrypted secret + encrypted data key)
    B->>C: Decrypt data key
    Note over D: Incurs cost per decryption request
    C->>D: Decrypt data key
    D->>C: Returns plain-text data key
    C->>B: Returns plain-text data key
    B->>B: Decrypts secret
    B-->>B: Discards plain-text data key
    B->>A: Returns secret
```

For security purpose, we decided to use Hardware Security Module (HSM) to protect the keys in GCP KMS.

## Consequences

### Authentication

With keys stored in GCP KMS, we need to de-multiplex between identities configured in GCP KMS and
identities defined in GitLab so that decryption requests can be authenticated accordingly.

### Cost

With the use of GCP KMS, we need to account for the following cost:

1. Number of keys required
1. Number of key operations
1. HSM Protection level

The number of keys required would be dependent on the number of projects, groups, and organizations using this feature.
A single asymmetric key is required for each project, group or organization.

Each cryptographic key operation would also incur cost and it varies per protection level.
Based on the proposed design above, this would incur cost at each secret decryption request.

We may implement a multi-tier protection level, supporting different protection types for different users.

The pricing table of GCP KMS can be found [here](https://cloud.google.com/kms/pricing).

### Feature availability for Self-Managed customers

Using GCP KMS as a backend means that this solution cannot be deployed into self-managed environments.
To make this feature available to Self-Managed customers, this feature needs to be a GitLab Cloud Connector feature.

## Alternatives

We considered generating and storing private keys within GitLab Secrets Service,
but this would not meet the requirements for [FIPS Compliance](../../../../development/fips_compliance.md).

On the other hand, GCP HSM Keys comply with [FIPS 140-2 Level 3](https://cloud.google.com/docs/security/key-management-deep-dive#fips_140-2_validation).
