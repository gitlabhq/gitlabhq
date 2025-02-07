---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Docker integration
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can incorporate [Docker](https://www.docker.com) into your CI/CD workflow in two primary ways:

- **[Run your CI/CD jobs](using_docker_images.md) in Docker containers.**

  You can create CI/CD jobs to do things like test, build, or publish
  an application. These jobs can run in Docker containers.

  For example, you can tell GitLab CI/CD to use a Node image that's hosted on Docker Hub
  or in the GitLab container registry. Your job then runs in a container that's based on the image.
  The container has all the Node dependencies you need to build your app.

- **Use [Docker](using_docker_build.md) or [kaniko](using_kaniko.md) to build Docker images.**

  You can create CI/CD jobs to build Docker images and publish
  them to a container registry.
