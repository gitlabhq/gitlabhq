---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Use GitLab as a microservice

Many applications need to access JSON APIs, so application tests might need access
to APIs too. The following example shows how to use GitLab as a microservice to give
tests access to the GitLab API.

1. Configure a [runner](../runners/index.md) with the Docker or Kubernetes executor.
1. In your `.gitlab-ci.yml` add:

   ```yaml
   services:
     - name: gitlab/gitlab-ce:latest
       alias: gitlab

   variables:
     GITLAB_HTTPS: "false"             # ensure that plain http works
     GITLAB_ROOT_PASSWORD: "password"  # to access the api with user root:password
   ```

1. To set values for the `GITLAB_HTTPS` and `GITLAB_ROOT_PASSWORD`,
   [assign them to a variable in the user interface](../variables/index.md#add-a-cicd-variable-to-a-project).
   Then assign that variable to the corresponding variable in your
   `.gitlab-ci.yml` file.

Then, commands in `script:` sections in your `.gitlab-ci.yml` file can access the API at `http://gitlab/api/v4`.

For more information about why `gitlab` is used for the `Host`, see
[How services are linked to the job](../docker/using_docker_images.md#extended-docker-configuration-options).

You can also use any other Docker image available on [Docker Hub](https://hub.docker.com/u/gitlab).

The `gitlab` image can accept environment variables. For more details,
see the [Omnibus documentation](../../install/index.md).
