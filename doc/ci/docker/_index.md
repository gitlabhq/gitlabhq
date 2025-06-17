---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Docker integration
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can incorporate [Docker](https://www.docker.com) into your CI/CD workflow in two primary ways:

- [Run your CI/CD jobs](using_docker_images.md) in Docker containers.

  Create jobs to test, build, or publish applications that run in Docker containers.
  For example, use a Node image from Docker Hub so your job runs in a container
  with all the Node dependencies you need.

- Use [Docker Build](using_docker_build.md) or [BuildKit](using_buildkit.md) to build Docker images.

  Create jobs that build Docker images and publish them to a container registry.
  BuildKit provides multiple approaches including rootless builds.
