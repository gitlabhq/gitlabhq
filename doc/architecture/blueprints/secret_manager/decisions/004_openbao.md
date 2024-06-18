---
owning-stage: "~devops::verify"
description: 'GitLab Secrets Manager ADR 004: Use OpenBao as the secrets management service'
---

# GitLab Secrets Manager ADR 004: Use OpenBao as the secrets management service

## Context

To store and maintain secrets securely in the GitLab Secrets Manager, we want to rely on a robust
system that can provide the necessary features that we need.

## Decision

Use [OpenBao](https://openbao.org/docs/what-is-openbao/), a fork of HashiCorp Vault, as the secrets management service.
This component will provide all the mechanism to securely store and manage secrets.
In terms of user-initiated modifications of secrets, GitLab Rails will act as an abstraction
layer and will delegate all tasks to this component.

Using OpenBao provides a few advantages:

1. Avoid implementing our own secure storage of secrets.
1. Support for Hardware Security Modules (HSM).
1. Leverage existing integration mechanism that we have for HashiCorp Vault because OpenBao maintains backwards compatibility with the open source edition of Vault.

## Consequences

To provide uninterrupted access to secrets, we need the OpenBao vault to always be unsealed.

We have to ensure that the proper policies and access rights are in place to prevent actors from obtaining secrets in an event that they gain access to the container running GitLab Rails.

Also, given the encryption, decryption, and storage of secrets all happen in the OpenBao server, we have to make sure to harden the security and prevent a breach of the vault instance.
