---
stage: Deploy
group: Environments
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Auto DevOps development guidelines
---

This document provides a development guide for contributors to
[Auto DevOps](../topics/autodevops/_index.md).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
An [Auto DevOps technical walk-through](https://youtu.be/G7RTLeToz9E)
is also available on YouTube.

## Development

Auto DevOps builds on top of GitLab CI/CD to create an automatic pipeline
based on your project contents. When Auto DevOps is enabled for a
project, the user does not need to explicitly include any pipeline configuration
through a `.gitlab-ci.yml` file.

In the absence of a `.gitlab-ci.yml` file, the
[Auto DevOps CI/CD template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Auto-DevOps.gitlab-ci.yml)
is used implicitly to configure the pipeline for the project. This
template is a top-level template that includes other sub-templates,
which then defines jobs.

Some jobs use images that are built from external projects:

- [Auto Build](../topics/autodevops/stages.md#auto-build) uses
  [configuration](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Build.gitlab-ci.yml)
  in which the `build` job uses an image that is built using the
  [`auto-build-image`](https://gitlab.com/gitlab-org/cluster-integration/auto-build-image)
  project.
- [Auto Deploy](../topics/autodevops/stages.md#auto-deploy) uses
  [configuration](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy.gitlab-ci.yml)
  in which the jobs defined in this template use an image that is built using the
  [`auto-deploy-image`](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image)
  project. By default, the Helm chart defined in
  [`auto-deploy-app`](https://gitlab.com/gitlab-org/cluster-integration/auto-deploy-image/-/tree/master/assets/auto-deploy-app) is used to deploy.

There are extra variables that get passed to the CI jobs when Auto
DevOps is enabled that are not present in a typical CI job. These can be
found in
[`ProjectAutoDevops`](https://gitlab.com/gitlab-org/gitlab/-/blob/bf69484afa94e091c3e1383945f60dbe4e8681af/app/models/project_auto_devops.rb).

## Development environment

See the [Simple way to develop/test Kubernetes workflows with a local cluster](https://gitlab.com/gitlab-org/gitlab-development-kit/-/issues/1064)
issue for discussion around setting up Auto DevOps development environments.

## Monitoring on GitLab.com

The metric
[`auto_devops_completed_pipelines_total`](https://dashboards.gitlab.net/explore?schemaVersion=1&panes=%7B%22m95%22:%7B%22datasource%22:%22e58c2f51-20f8-4f4b-ad48-2968782ca7d6%22,%22queries%22:%5B%7B%22refId%22:%22A%22,%22expr%22:%22sum%28increase%28auto_devops_pipelines_completed_total%7Benvironment%3D%5C%22gprd%5C%22%7D%5B60m%5D%29%29%20by%20%28status%29%22,%22range%22:true,%22instant%22:true,%22datasource%22:%7B%22type%22:%22prometheus%22,%22uid%22:%22e58c2f51-20f8-4f4b-ad48-2968782ca7d6%22%7D,%22editorMode%22:%22code%22,%22legendFormat%22:%22__auto%22%7D%5D,%22range%22:%7B%22from%22:%22now-1h%22,%22to%22:%22now%22%7D%7D%7D&orgId=1)
(only available to GitLab team members) counts completed Auto DevOps
pipelines, labeled by status.
