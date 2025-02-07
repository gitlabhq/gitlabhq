---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use GitLab as a microservice
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Many applications need to access JSON APIs, so application tests might need access
to APIs too. The following example shows how to use GitLab as a microservice to give
tests access to the GitLab API.

1. Configure a [runner](../runners/_index.md) with the Docker or Kubernetes executor.
1. In your `.gitlab-ci.yml` add:

   ```yaml
   services:
     - name: gitlab/gitlab-ce:latest
       alias: gitlab

   variables:
     GITLAB_HTTPS: "false"             # ensure that plain http works
     GITLAB_ROOT_PASSWORD: "password"  # to access the api with user root:password
   ```

NOTE:
Variables set in the GitLab UI are not passed down to the service containers.
For more information, see [GitLab CI/CD variables](../variables/_index.md).

Then, commands in `script` sections in your `.gitlab-ci.yml` file can access the API at `http://gitlab/api/v4`.

For more information about why `gitlab` is used for the `Host`, see
[How services are linked to the job](../docker/using_docker_images.md#extended-docker-configuration-options).

You can also use any other Docker image available on [Docker Hub](https://hub.docker.com/u/gitlab).

The `gitlab` image can accept environment variables. For more details,
see the [Omnibus documentation](../../install/_index.md).
