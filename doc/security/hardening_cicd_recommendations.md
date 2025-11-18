---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Hardening - CI/CD Recommendations
---

General hardening guidelines and philosophies are outlined in the [main hardening documentation](hardening.md).

The hardening recommendations and concepts for CI/CD are discussed in the following section.

## Basic Recommendations

How you configure the different CI/CD settings depends on your use of CI/CD. For example if you are using it to build
packages, you often need real-time access to external resources such as Docker
images or external code repositories. If you are using it for Infrastructure
as Code (IaC), you often need to store credentials for external systems to
automate deployment. For these and many other scenarios, you need to store
potentially sensitive information to be used during CI/CD operations. As the
individual scenarios themselves are numerous, some basic information is
summarized to help harden the CI/CD process.

The general guidance is to:

- Protect secrets.
- Ensure network communications are encrypted.
- Use thorough logging for auditing and troubleshooting purposes.

## Specific Recommendations

Pipelines are a core component of GitLab CI/CD that execute jobs in stages to automate tasks
on behalf of the users of a project. For specific guidelines on dealing with pipelines,
see the information on [pipeline security](../ci/pipeline_security/_index.md).

Deployment is the part of the CI/CD that deploys the results of the pipeline in
relationship to a given environment. Default settings do not impose many
restrictions, and as different users with different roles and responsibilities can
trigger pipelines that can interact with those environments, you should
restrict these environments. For more information, see
[protected environments](../ci/environments/protected_environments.md).
