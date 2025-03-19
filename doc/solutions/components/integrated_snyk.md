---
stage: Solutions Architecture
group: Solutions Architecture
info: This page is owned by the Solutions Architecture team.
title: GitLab Application Security Workflow Integrated with Snyk
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

## Getting Started

### Download the Solution Component

1. Obtain the invitation code from your account team.
1. Download the solution component from [the solution component webstore](https://cloud.gitlab-accelerator-marketplace.com) by using your invitation code.

## Snyk Integration

This is an integration between Snyk and GitLab CI via a GitLab CI/CD Component.

## How it works

This project has a component that runs the Snyk CLI and outputs the scan report in the SARIF format. It calls a separate component that converts SARIF to the GitLab vulnerability record format using a job based on the semgrep base image.

There is a versioned container in the container registry that has a node base image with the Snyk CLI installed on top. This is the image used in the Snyk component job.
The `.gitlab-ci.yml` file builds the container image, tests, and versions the component.

### Versioning

This project follows semantic versioning.
