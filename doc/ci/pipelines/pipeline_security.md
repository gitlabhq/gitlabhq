---
stage: Software Supply Chain Security
group: Pipeline Security
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Pipeline security
description: Secrets management, job tokens, secure files, and cloud security.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Secrets Management

Secrets management is the systems that developers use to securely store sensitive data
in a secure environment with strict access controls. A **secret** is a sensitive credential
that should be kept confidential. Examples of a secret include:

- Passwords
- SSH keys
- Access tokens
- Any other types of credentials where exposure would be harmful to an organization

## Secrets storage

### Secrets management providers

Secrets that are the most sensitive and under the strictest policies should be stored
in a secrets manager. When using a secrets manager solution, secrets are stored outside
of the GitLab instance. There are a number of providers in this space, including
[HashiCorp's Vault](https://www.vaultproject.io), [Azure Key Vault](https://azure.microsoft.com/en-us/products/key-vault),
and [Google Cloud Secret Manager](https://cloud.google.com/security/products/secret-manager).

You can use the GitLab native integrations for certain [external secret management providers](../secrets/_index.md) to retrieve those secrets in CI/CD pipelines when they are needed.

### CI/CD variables

[CI/CD Variables](../variables/_index.md) are a convenient way to store and reuse data
in a CI/CD pipeline, but variables are less secure than secrets management providers.
Variable values:

- Are stored in the GitLab project, group, or instance settings. Users with access
  to the settings have access to variables values that are not [hidden](../variables/_index.md#hide-a-cicd-variable).
- Can be [overridden](../variables/_index.md#use-pipeline-variables),
  making it hard to determine which value was used.
- Can be exposed by accidental pipeline misconfiguration.

Information suitable for storage in a variable should be data that can be exposed without risk of exploitation (non-sensitive).

Sensitive data should be stored in a secrets management solution. If you don't have
a secrets management solution and want to store sensitive data in a CI/CD variable, be sure to always:

- [Mask the variables](../variables/_index.md#mask-a-cicd-variable).
- [Hide the variables](../variables/_index.md#hide-a-cicd-variable).
- [Protect the variables](../variables/_index.md#protect-a-cicd-variable) when possible.

## Pipeline Integrity

The key security principals of ensuring pipeline integrity include:

- **Supply Chain Security**: Assets should be obtained from trusted sources and their integrity verified.
- **Reproducibility**: Pipelines should produce consistent results when using the same inputs.
- **Auditability**: All pipeline dependencies should be traceable and their provenance verifiable.
- **Version Control**: Changes to pipeline dependencies should be tracked and controlled.

### Docker images

Always use SHA digests for Docker images to ensure client-side integrity verification.
For example:

- Node:
  - Use: `image: node@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef`
  - Instead of: `image: node:latest`
- Python:
  - Use `image: python@sha256:9876543210abcdef9876543210abcdef9876543210abcdef9876543210abcdef`
  - Instead of: `image: python:3.9`

You can find the SHA digest of an image with a specific tag using:

```shell
docker pull node:18.17.1
docker images --digests node:18.17.1
```

Prefer to pull from container registries that protect image integrity:

- Use [protected container repositories](../../user/packages/container_registry/container_repository_protection_rules.md)
  to restrict which users can make changes to container images in your container repository.
- Use [protected tags](../../user/packages/container_registry/protected_container_tags.md)
  to control who can push and delete container tags.

When possible, avoid using variables in container references as they can be modified to point to malicious images.
For example:

- Prefer:
  - `image: my-registry.example.com/node:18.17.1`
- Instead of:
  - `image: ${CUSTOM_REGISTRY}/node:latest`
  - `image: node:${VERSION}`

### Package dependencies

You should lock down package dependencies in your jobs. Use exact versions, defined in lock files:

- npm:
  - Use: `npm ci`
  - Instead of: `npm install`
- yarn:
  - Use: `yarn install --frozen-lockfile`
  - Instead of: `yarn install`
- Python:
  - Use:
    - `pip install -r requirements.txt --require-hashes`
    - `pip install -r requirements.lock`
  - Instead of: `pip install -r requirements.txt`
- Go:
  - Use exact versions from `go.sum`:
    - `go mod verify`
    - `go mod download`
  - Instead of: `go get ./...`

For example, in a CI/CD job:

```yaml
javascript-job:
  script:
    - npm ci
```

### Shell commands and scripts

When installing tools in a job, always specify and verify exact versions.
For example, in a Terraform job:

```yaml
terraform_job:
  script:
    # Download specific version
    - |
      wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
      # IMPORTANT: Always verify checksums
      echo "c0ed7bc32ee52ae255af9982c8c88a7a4c610485cf1d55feeb037eab75fa082c terraform_1.5.7_linux_amd64.zip" | sha256sum -c
      unzip terraform_1.5.7_linux_amd64.zip
      mv terraform /usr/local/bin/
    # Use the installed version
    - terraform init
    - terraform plan
```

### Version management tools

Use version managers when possible:

```yaml
node_build:
  script:
    # Use nvm to install and use a specific Node version
    - |
      nvm install 16.15.1
      nvm use 16.15.1
    - node --version  # Verify version
    - npm ci
    - npm run build
```

### Included configurations

When using the [`include` keyword](../yaml/_index.md#include) to add configuration
or CI/CD components to your pipeline, use a specific ref when possible. For example:

```yaml
include:
  - project: 'my-group/my-project'
    ref: 8b0c8b318857c8211c15c6643b0894345a238c4e  # Pin to a specific commit
    file: '/templates/build.yml'
  - project: 'my-group/security'
    ref: v2.1.0                                    # Pin to a protected tag
    file: '/templates/scan.yml'
  - component: 'my-group/security-scans'           # Pin to a specific version
    version: '1.2.3'
```

Avoid versionless includes:

```yaml
include:
  - project: 'my-group/my-project'                   # Unsafe
    file: '/templates/build.yml'
  - component: 'my-group/security-scans'             # Unsafe
  - remote: 'https://example.com/security-scan.yml'  # Unsafe
```

Instead of including remote files, download the file and save it in your repository.
Then you can include the local copy:

```yaml
include:
  - local: '/ci/security-scan.yml'  # Verified and stored in the repository
```

### Automatic SLSA attestation generation

GitLab offers a SLSA Level 1 compliant attestation that can be [automatically generated for all build artifacts produced by the GitLab Runner](../runners/configure_runners.md#artifact-provenance-metadata).
This attestation is produced by the runner itself.

### Related topics

1. [CIS Docker Benchmarks](https://www.cisecurity.org/benchmark/docker)
1. Google Cloud: [Design secure deployment pipelines](https://cloud.google.com/architecture/design-secure-deployment-pipelines-bp)
