---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use Auto DevOps to deploy to Amazon ECS
---

You can choose to target AWS ECS as a deployment platform instead of using Kubernetes.

To get started on Auto DevOps to AWS ECS, you must add a specific CI/CD variable.
To do so, follow these steps:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **Auto DevOps**.
1. Specify which AWS platform to target during the Auto DevOps deployment
   by adding the `AUTO_DEVOPS_PLATFORM_TARGET` variable with one of the following values:
   - `FARGATE` if the service you're targeting must be of launch type FARGATE.
   - `ECS` if you're not enforcing any launch type check when deploying to ECS.

When you trigger a pipeline, if you have Auto DevOps enabled and if you have correctly
[entered AWS credentials as variables](../../../ci/cloud_deployment/_index.md#authenticate-gitlab-with-aws),
your application is deployed to AWS ECS.

If you have both a valid `AUTO_DEVOPS_PLATFORM_TARGET` variable and a Kubernetes cluster tied to your project,
only the deployment to Kubernetes runs.

WARNING:
Setting the `AUTO_DEVOPS_PLATFORM_TARGET` variable to `ECS` triggers jobs
defined in the [`Jobs/Deploy/ECS.gitlab-ci.yml` template](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/gitlab/ci/templates/Jobs/Deploy/ECS.gitlab-ci.yml).
However, it's not recommended to [include](../../../ci/yaml/_index.md#includetemplate)
it on its own. This template is designed to be used with Auto DevOps only. It may change
unexpectedly causing your pipeline to fail if included on its own. Also, the job
names within this template may also change. Do not override these jobs' names in your
own pipeline, as the override stops working when the name changes.
