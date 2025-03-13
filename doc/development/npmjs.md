---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: npm package publishing guidelines
---

GitLab uses npm packages as a means to improve code reuse and modularity in and across projects.
This document outlines the best practices and guidelines for securely publishing npm packages to npmjs.com.

By adhering to these guidelines, we can ensure secure and reliable publishing of NPM packages,
fostering trust and consistency in the GitLab ecosystem.

## Setting up an npm account

1. Use your GitLab corporate email ID when creating an account on [npmjs.com](https://www.npmjs.com/).
1. Enable **Two-Factor Authentication (2FA)** for enhanced security.
1. Communicate any account changes (for example, email updates, ownership transfers) to the directly responsible teams via issues.

## Guidelines for publishing packages

### Security and ownership

1. If using npm aliases, verify that the packages referred to by the alias are legitimate and secure.
   You can do this by running `npm info <yourpackage> alias` to verify what a given alias points to.
   Ensure that you're confident that all aliases point to legitimate packages that you trust.
1. Avoid publishing secrets to npm registries (for example, npmjs.com, [GitLab npm registry](../user/packages/npm_registry/_index.md), etc) by enabling in the GitLab project:
   - **[Secret push protection](../user/application_security/secret_detection/secret_push_protection/_index.md)**
   - **[Secret detection](../user/application_security/secret_detection/pipeline/_index.md)**
1. Secure NPM tokens used for registry interactions:
   - Strongly consider using an external secret store like OpenBao or Vault
   - At a minimum, store tokens [securely](../ci/pipelines/pipeline_security.md#cicd-variables) in environment variables
     in GitLab CI/CD pipelines, ensuring that masking and protection is enabled.
   - Do not store tokens on your local machine in unsecured locations. Please store tokens in 1Password and
     refrain from storing these secrets in unencrypted files like shell profiles, `.npmrc`, and `.env`.
1. Add `gitlab-bot` as author of the package. This ensures the organization retains ownership if a team member's email becomes invalid during offboarding.

### Dependency Integrity

1. Use **lock files** (`package-lock.json` or `yarn.lock`) to ensure consistency in dependencies across environments.
1. Consider performing [dependency pinning/specification](https://docs.npmjs.com/specifying-dependencies-and-devdependencies-in-a-package-json-file)
   to lock specific versions and prevent unintended upgrades to malicious or vulnerable versions.
   This may make upgrading dependencies more involved.
1. Use `npm ci` (or `yarn install --frozen-lockfile`) instead of `npm install` in CI/CD pipelines
   to ensure dependencies are installed exactly as defined in the lock file.
1. [Run untamper-my-lockfile](https://gitlab.com/gitlab-org/frontend/untamper-my-lockfile/#usage) to protect lockfile integrity.

### Enforcing CI/CD-Only Publishing

Packages **must only be published through GitLab CI/CD pipelines on a protected branch**, not from local developer machines. This ensures:

- Secrets are managed securely
- Handoffs between team members are seamless, as workflows are documented and automated.
- The risk of accidental exposure or unauthorized publishing is minimized.

To set up publishing through GitLab CI/CD:

1. Configure a job in `.gitlab-ci.yml` for publishing the package. An example is provided [below](#example-cicd-configuration)
1. Store the NPM token securely. This may look like using an external secret storage utility like OpenBAO or Vault.
   As a last resort, use GitLab CI/CD variables with masking and protection enabled.
1. Ensure the pipeline includes steps for secret detection and code quality checks before publishing.

### Secure registry access

1. Use **scoped packages** (`@organization-name/package-name`) to prevent namespace pollution or name-squatting by other users.
1. Restrict registry permissions:
   - Use **organization-specific NPM scopes** and enforce permissions for accessing or publishing packages.

### Securing package metadata

1. Avoid exposing sensitive information in the `package.json` file:
   - Ensure no secrets or internal URLs (for example, private API endpoints) are included.
   - Limit `files` in `package.json` to explicitly include only necessary files in the published package.
1. If the package is not meant to be public, control visibility with `publishConfig.access: 'restricted'`.

### Example CI/CD configuration

Below is an example `.gitlab-ci.yml` configuration for publishing an NPM package. This codeblock isn't meant to be used as-is and will require changes depending on your configuration. This means that you will need to modify the example below to include the location of your npmjs publishing token.

```yaml
stages:
  - test
  - build
  - deploy

test:
  stage: test
  image: node:22
  script:
    - npm ci
    - npm test

build:
  stage: build
  image: node:18
  script:
    - npm ci
    - npm run build

publish:
  stage: deploy
  image: node:22
  script:
    - npm ci
    - npm run build
    - npm publish
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

## Best Practices for Package Security

1. Enable npm **2FA for package publishing** to prevent unauthorized publishing.
1. Enable GitLab [Dependency Scanning](../user/application_security/dependency_scanning/_index.md)
   on the project and regularly review the vulnerability report.
1. Monitor published packages for unusual activity or unauthorized updates.
1. Document the purpose and scope of the package in the `README.md` to ensure clear communication with users.

## Examples of secure package names

- `unique-package`: Generic package not specific to GitLab.
- `existing-package-gitlab`: A forked package with GitLab-specific modifications.
- `@gitlab/specific-package`: A package developed for internal GitLab use.

## Avoiding local secrets and manual publishing

Manual workflows should be avoided to ensure that:

- **Secrets remain secure:** Tokens and other sensitive information should only exist in secure CI/CD environments.
- **Workflows are consistent and auditable:** CI/CD pipelines ensure that all publishing steps are repeatable and documented.
- **Complexity is reduced:** Centralized CI/CD pipelines simplify project handovers and minimize risks.
