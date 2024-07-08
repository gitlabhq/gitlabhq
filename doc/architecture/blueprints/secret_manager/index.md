---
status: proposed
creation-date: "2023-08-07"
authors: [ "@alberts-gitlab", "@iamricecake" ]
coach: [ "@grzesiek", "@fabiopitino" ]
approvers: [ "@jocelynjane", "@shampton" ]
owning-stage: "~sec::govern"
participating-stages: []
---

<!-- Blueprints often contain forward-looking statements -->
<!-- vale gitlab.FutureTense = NO -->

# GitLab Secrets Manager

## Summary

GitLab users need a secure and easy-to-use solution to
store their sensitive credentials that should be kept confidential ("secret").
GitLab Secrets Manager is the desired system that provides GitLab users
to meet that need without having to access third party tools.

## Motivation

The current de-facto approach used by many to store a sensitive credential in GitLab is
using a [Masked Variable](../../../ci/variables/index.md#mask-a-cicd-variable) or a
[File Variable](../../../ci/variables/index.md#use-file-type-cicd-variables).
However, data stored in variables (masked or file variables) can be inadvertently exposed even with masking.
A more secure solution would be to use native integration
with external secret managers such as HashiCorp Vault or Azure Key Vault.

Integration with external secret managers requires GitLab to maintain the integration
with the third-party products and to assist customers in troubleshooting configuration issues.
In addition, customer's engineering teams using these external secret managers
may need to maintain these systems themselves, adding to the operational burden.

Having a GitLab native secret manager would provide customers a secure method to store and access secrets
without the overhead of third party tools and to leverage the tight integration with other GitLab features.

### Goals

Provide GitLab users with a way to:

- Securely store secrets in GitLab
- Use the stored secrets in GitLab components (for example, CI Runner)
- Use the stored secrets in external environments (for example, production infrastructure).
- Manage access to secrets across a root namespace, subgroups and projects.

#### Use Cases

To help design the architecture, we need to understand how users, in their roles, would
operate and use the system. Here are significant use case scenarios that can help drive our
design decisions:

1. As a Compliance Manager or Security Ops engineer, I want to use dynamic secrets to provide an additional layer of security for my system.
1. As a Compliance Manager or Security Ops engineer, I want to use automatic secret rotation to provide an additional layer of security for my system.
1. As a Compliance Manager or Security Ops engineer, I want to set secrets expiration policies to provide an additional layer of security for my system.
1. As a Developer, I want sensitive credentials to be fully encrypted so I am not accidentally leaking this information in my deliverables.
1. As a Developer, I want to use secrets to store sensitive credentials to avoid storing this information inside of my code.
1. As a GitLab Admin and as a GitLab Group Owner, I want to have the ability to disable secrets management feature altogether if my organization requires the use of a 3rd party tool.
1. As a Compliance Manager or Security Ops engineer, I need to have audit tools which will show me the status of the secrets, their usage so I can identify any suspicious behavior and ensure our security and compliance of our sensitive credentials.
1. As a Compliance Manager, I need to audit log of secrets usage and management to ensure my organization is following compliance policy.
1. As a DevOps Engineer, I want the deployment process to fetch secrets necessary for deployment directly from a secrets manager.
1. As a Customer of a regulated industry, I need a secrets manager with HSM support so I can meet FIPS requirements.
1. As a US Public Sector customer, I need a secrets manager that is FedRAMP certified to meet security requirements.
1. As a Customer with an air-gapped system, I need a secrets managers that can be installed on-prem and managed on-site to meet network requirements.
1. As a Secret Owner, I need to quickly update or rotate the secret in case there has been a vulnerability to ensure the security of my software supply chain.
1. As a Secret Owner, I need the ability to rollback change to a secret in the event of an accidental change.
1. As a Security Engineer, I want to ensure all secrets are properly deleted/destroyed if they are no longer needed.

#### Non-functional requirements

- Security
- Compliance
- Auditability

### Non-Goals

This blueprint does not cover the following:

- Secrets such as access tokens created within GitLab to allow external resources to access GitLab, e.g personal access tokens.

## Decisions

- [ADR-004: Use OpenBao as the secrets management service](decisions/004_openbao.md)
- [ADR-005: Non-hierarchical key structure for secrets in OpenBao](decisions/005_secrets_key_structure.md)
- [ADR-006: Use AppRole authentication method between Rails and OpenBao](decisions/006_approle_authentication_rails.md)

### Superseded

These documents are part of the initial iteration of this blueprint.

- [ADR-001: Use envelope encryption](decisions/001_envelop_encryption.md)
- [ADR-002: Use GCP Key Management Service](decisions/002_gcp_kms.md)
- [ADR-003: Build Secrets Manager in Go](decisions/003_go_service.md)

## Proposal

The secrets manager feature will be available on both SaaS and Self-Managed installations
and will consist of two core components:

1. GitLab Rails
1. OpenBao Server

```mermaid
flowchart LR
c([Consumer]) --interacts with-->glab[GitLab Rails]--with backend-->o[OpenBao]
```

A consumer can be:

1. A user who interacts manually with a client library, API, or UI.
1. An integration, for example, Vault integration on Runner.

### GitLab Rails

GitLab Rails would be the main interface that users would interact with when managing secrets using the Secrets Manager feature.

This component is a facade to OpenBao server.

#### Retrieve user secrets

To retrieve secrets for a given user and display them in GitLab UI we will create a new table to persist secrets metadata. Otherwise we can't pull all the secrets belonging to a user as there is no `OpenBao` endpoint to achieve this.

Here a `SQL` example of how this could look like:

```sql
CREATE TABLE secrets (
   id bigint NOT NULL,
   environment_id bigint,
   project_id bigint,
   group_id bigint,
   created_at timestamp with time zone NOT NULL,
   updated_at timestamp with time zone NOT NULL,
   revoked_at timestamp with time zone,
   expiration_date date,
   name text,
   description text,
   branch_name text
)
```

Based on this metadata, we will be able to determine the secret path in `OpenBao` by using the name provided by the user: `kv-v2/data/projects/<project_id>/<secret#name>`.

### OpenBao Server

OpenBao Server will be a new component in the GitLab overall architecture. This component provides all the secrets management capabilities
including storing the secrets themselves.

### Use Case Studies

- [Using secrets in a CI job](studies/ci_job_secrets.md)

### Further investigations required

1. Authentication of clients other than GitLab Runner.
   GitLab Runner authenticates using JWT, for other types of clients, we need a secure and reliable method to authenticate requests to decrypt a secret.
1. How to namespace data, roles and policies to specific tenant.
1. How to allow organizations to seal/unseal secrets vault on demand.
1. Infrastructure setup, including how OpenBao will be installed for self-managed instances.
1. How to best implement sharing of secrets between multiple groups in GitLab.
1. Establish our protocol and processes for incidents that may require sealing the secrets vault.
1. How to support protected and environment specific rules for secrets.
1. How to audit secret changes. Do we want to use [audit socket](https://openbao.org/docs/audit/socket/)?
1. Do we want to structure project secret paths to be under namespaces to increase isolation between tenants?
1. Should the secrets be revoked if a project or subgroup is moved under a different top-level group/organization?

## Alternative Solutions

Other solutions we have explored:

- Separating secrets from CI/CD variables as a separate model with limited access, to avoid unintended exposure of the secret.
- [Secure Files](../../../ci/secure_files/index.md)

## References

The following links provide additional information that may be relevant to secret management concepts.

- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [OWASP Key Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Key_Management_Cheat_Sheet.html)

## Who

DRIs:

<!-- vale gitlab.Spelling = NO -->

| Role                | Who                                            |
|---------------------|------------------------------------------------|
| Author              | Erick Bajao, Senior Engineer                   |
| Recommender         | Fabio Pitino, Principal Engineer               |
| Product Leadership  | Jocelyn Eillis , Product Manager               |
| Engineering Leadership | Scott Hampton, Engineering Manager          |
| Lead Engineer       | Erick Bajao, Senior Backend Engineer           |
| Senior Engineer     | Maxime Orefice, Senior Backend Engineer        |
| Engineer            | Shabini Rajadas, Backend Engineer              |

<!-- vale gitlab.Spelling = YES -->
