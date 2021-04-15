---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Using GitLab

As many applications depend on accessing JSON apis you eventually need them in order for your tests to run.
In this example we are providing GitLab as a Microservice to be accessible for API clients.
Below you are guided how to do this with the Docker executors of GitLab Runner.

## Use GitLab with the Docker executor

If you're using [GitLab Runner](../runners/README.md) with the Docker/Kubernetes executor,
you basically have everything set up already.

First, in your `.gitlab-ci.yml` add:

```yaml
services:
  - name: gitlab/gitlab-ce:latest
    alias: gitlab

variables:
  GITLAB_HTTPS: "false"             # ensure that plain http will work
  GITLAB_ROOT_PASSWORD: "password"  # in order to access the api with user root:password
```

To set values for the `GITLAB_HTTPS`, `GITLAB_ROOT_PASSWORD`,
[assign them to a variable in the user interface](../variables/README.md#project-cicd-variables),
then assign that variable to the corresponding variable in your
`.gitlab-ci.yml` file.

From your ci `script:` the API will then be availible at `http://gitlab/api/v4`

If you're wondering why we used `gitlab` for the `Host`, read more at
[How services are linked to the job](../docker/using_docker_images.md#extended-docker-configuration-options).

You can also use any other Docker image available on [Docker Hub](https://hub.docker.com/u/gitlab).

The `gitlab` image can accept some environment variables. For more details,
see the [omnibus documentation](../../install/README.md).
