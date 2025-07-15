---
stage: none
group: Tutorials
info: For assistance with this tutorials page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: Deployment processes and targets.
title: 'Tutorials: Deploy and release your application'
---

## Manage packages and containers

Learn how to use package and container registries to manage your artifacts.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [GitLab Package and Release Functions](https://university.gitlab.com/courses/gitlab-package-and-release-functions) | Learn the basics of registries and release features in this self-paced course. | {{< icon name="star" >}} |
| [Automatically build and publish packages with CI/CD](../user/packages/pypi_repository/auto_publish_tutorial.md) | Learn how to automatically build, test, and publish a PyPI package to the package registry. | {{< icon name="star" >}} |
| [Structure the package registry for enterprise scale](../user/packages/package_registry/enterprise_structure_tutorial.md) | Set up your organization to upload, manage, and consume packages at scale. | |
| [Build and sign Python packages with GitLab CI/CD](../user/packages/package_registry/pypi_cosign_tutorial.md)  | Learn how to build a secure pipeline for Python packages using GitLab CI/CD and Sigstore Cosign. | |
| [Annotate container images with build provenance data](../user/packages/container_registry/cosign_tutorial.md) | Learn how to automate the process of building, signing, and annotating container images using Cosign. | |
| [Migrate container images from Amazon ECR to GitLab](../user/packages/container_registry/migrate_containers_ecr_tutorial.md) | Automate the bulk migration of container images from Amazon Elastic Container Registry (ECR) to the GitLab container registry. | |

## Publish a static website

Use GitLab Pages to publish a static website directly from your project.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [Create a Pages website from a CI/CD template](../user/project/pages/getting_started/pages_ci_cd_template.md) | Quickly generate a Pages website for your project using a CI/CD template for a popular Static Site Generator (SSG). | {{< icon name="star" >}} |
| [Create a Pages website from scratch](../user/project/pages/getting_started/pages_from_scratch.md) | Create all the components of a Pages website from a blank project. | |
| [Build, test, and deploy your Hugo site with GitLab](hugo/_index.md) | Generate your Hugo site using a CI/CD template and GitLab Pages. | {{< icon name="star" >}} |
