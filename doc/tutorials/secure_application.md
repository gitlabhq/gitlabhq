---
stage: none
group: Tutorials
info: For assistance with this tutorials page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: Dependency and compliance scanning.
title: 'Tutorials: Secure your application and check compliance'
---

GitLab can check your application for security vulnerabilities and that it meets compliance requirements.

## Learn security fundamentals

Start here to understand the security basics at GitLab.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [GitLab Security Essentials](https://university.gitlab.com/courses/security-essentials) | Learn about the essential security capabilities of GitLab in this self-paced course. | {{< icon name="star" >}}  |
| [Get started with GitLab application security](../user/application_security/get-started-security.md) | Follow recommended steps to set up security tools. | |

## Set up basic security detection

Create fundamental scans to identify vulnerabilities.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [Set up dependency scanning](dependency_scanning.md) | Learn how to detect vulnerabilities in an application's dependencies. | {{< icon name="star" >}} |
| [Scan a Docker container for vulnerabilities](container_scanning/_index.md) | Learn how to use container scanning templates to add container scanning to your projects. | {{< icon name="star" >}} |
| [A comprehensive guide to GitLab DAST](https://about.gitlab.com/blog/comprehensive-guide-to-gitlab-dast/) | Learn how to configure dynamic application security testing, perform scans, and implement security policies. | {{< icon name="star" >}} |

## Protect against secret exposure

Prevent sensitive data from being committed to your repository.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [Protect your project with secret push protection](../user/application_security/secret_detection/push_protection_tutorial.md) | Enable secret push protection in your project. | {{< icon name="star" >}} |
| [Detect secrets committed to a project](../user/application_security/secret_detection/pipeline/tutorial.md) | Learn how to detect and remediate secrets committed to your project's repository. | {{< icon name="star" >}} |
| [Remove a secret from your commits](../user/application_security/secret_detection/remove_secrets_tutorial.md) | Learn how to remove a secret from your commit history. | {{< icon name="star" >}} |

## Implement security policies and governance

Enforce security requirements across your projects.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [Set up a scan execution policy](scan_execution_policy/_index.md) | Learn how to create a scan execution policy to enforce security scanning of your project. | {{< icon name="star" >}} |
| [Set up a pipeline execution policy](pipeline_execution_policy/_index.md) | Learn how to create a pipeline execution policy to enforce security scanning across projects as part of the pipeline. | {{< icon name="star" >}} |
| [Set up a merge request approval policy](scan_result_policy/_index.md) | Learn how to configure a merge request approval policy that takes action based on scan results. | {{< icon name="star" >}} |

## Establish compliance and reporting

Meet regulatory requirements and generate compliance documentation.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [Generate a software bill of materials with GitLab package registry](../user/packages/package_registry/tutorial_generate_sbom.md) | Learn how to generate an SBOM across all projects in a group. | {{< icon name="star" >}} |
| [Export dependency list in SBOM format](export_sbom.md) | Learn how to export an application's dependencies to the CycloneDX SBOM format. | {{< icon name="star" >}} |
