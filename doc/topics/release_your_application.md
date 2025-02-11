---
stage: none
group: unassigned
description: Environments, packages, review apps, GitLab Pages.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Deploy and release your application
---

Deployment is the step of the software delivery process when your
application gets deployed to its final, target infrastructure.

You can deploy your application internally or to the public.
Preview a release in a review app, and use feature flags to
release features incrementally.

| | | |
|--|--|--|
| [**Getting started**](../user/get_started/get_started_deploy_release.md)<br>Overview of how features fit together. | [**Packages and registries**](../user/packages/_index.md)<br>Package management, container registry, artifact storage, dependency management. | [**Environments**](../ci/environments/_index.md)<br>Environments, variables, dashboards, review apps. |
| [**Deployments**](../ci/environments/deployments.md)<br>Deployments, rollbacks, safety, approvals. | [**Releases**](../user/project/releases/_index.md)<br>Releases, versioning, assets, tags, milestones, evidence. | [**Roll out an application incrementally**](../ci/environments/incremental_rollouts.md)<br>Kubernetes, CI/CD, risk mitigation, deployment. |
| [**Feature flags**](../operations/feature_flags.md)<br>Progressive delivery, controlled deployment, risk reduction. | [**GitLab Pages**](../user/project/pages/_index.md)<br>Static site hosting, documentation publishing, project websites, custom domains. | |

## Related topics

- [Auto DevOps](autodevops/_index.md) is an automated CI/CD-based workflow that supports the entire software
  supply chain: build, test, lint, package, deploy, secure, and monitor applications using GitLab CI/CD.
  It provides a set of ready-to-use templates that serve the vast majority of use cases.
- [Auto Deploy](autodevops/stages.md#auto-deploy) is the DevOps stage dedicated to software
  deployment using GitLab CI/CD. Auto Deploy has built-in support for EC2 and ECS deployments.
- Deploy to Kubernetes clusters by using the [GitLab agent](../user/clusters/agent/install/_index.md).
- Use Docker images to run AWS commands from GitLab CI/CD, and a template to
  facilitate [deployment to AWS](../ci/cloud_deployment/_index.md).
- Use GitLab CI/CD to target any type of infrastructure accessible by GitLab Runner.
  [User and pre-defined environment variables](../ci/variables/_index.md) and CI/CD templates
  support setting up a vast number of deployment strategies.
- Use GitLab [Cloud Seed](../cloud_seed/_index.md), an open-source Incubation Engineering program,
  to set up deployment credentials and deploy your application to Google Cloud Run with minimal friction.
