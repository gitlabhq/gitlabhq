---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Deploy to Amazon Elastic Container Service
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This step-by-step guide helps you deploy a project hosted on GitLab.com to
the Amazon [Elastic Container Service (ECS)](https://aws.amazon.com/ecs/).

In this guide, you begin by creating an ECS cluster manually using the AWS console. You create and
deploy a simple application that you create from a GitLab template.

These instructions work for both GitLab.com and GitLab Self-Managed instances.
Ensure your own [runners are configured](../../runners/_index.md).

## Prerequisites

- An [AWS account](https://repost.aws/knowledge-center/create-and-activate-aws-account).
  Sign in with an existing AWS account or create a new one.
- In this guide, you create an infrastructure in [`us-east-2` region](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html).
  You can use any region, but do not change it after you begin.

## Create an infrastructure and initial deployment on AWS

For deploying an application from GitLab, you must first create an infrastructure and initial
deployment on AWS.
This includes an [ECS cluster](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/clusters.html)
and related components, such as
[ECS task definitions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html),
[ECS services](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html),
and containerized application image.

For the first step here, you create a demo application from a project template.

### Create a new project from a template

Use a GitLab project template to get started. As the name suggests, these projects provide a
bare-bones application built on some well-known frameworks.

1. In GitLab on the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Create from template**, where you can choose from a Ruby on Rails, Spring, or
   NodeJS Express project. For this guide, use the Ruby on Rails template.
1. Give your project a name. In this example, it's named `ecs-demo`. Make it public so that you can
   take advantage of the features available in the
   [GitLab Ultimate plan](https://about.gitlab.com/pricing/).
1. Select **Create project**.

Now that you created a demo project, you must containerize the application and push it to the
container registry.

### Push a containerized application image to GitLab container registry

[ECS](https://aws.amazon.com/ecs/) is a container orchestration service, meaning that you must
provide a containerized application image during the infrastructure build. To do so, you can use
GitLab [Auto Build](../../../topics/autodevops/stages.md#auto-build)
and [Container Registry](../../../user/packages/container_registry/_index.md).

1. On the left sidebar, select **Search or go to** and find your `ecs-demo` project.
1. Select **Set up CI/CD**. It brings you to a `.gitlab-ci.yml`
   creation form.
1. Copy and paste the following content into the empty `.gitlab-ci.yml`. This defines
   a pipeline for continuous deployment to ECS.

   ```yaml
   include:
     - template: AWS/Deploy-ECS.gitlab-ci.yml
   ```

1. Select **Commit Changes**. It automatically triggers a new pipeline. In this pipeline, the `build`
   job containerizes the application and pushes the image to [GitLab container registry](../../../user/packages/container_registry/_index.md).

1. Visit **Deploy > Container Registry**. Make sure the application image has been
   pushed.

   ![A containerized application image in the container registry.](img/registry_v13_10.png)

Now you have a containerized application image that can be pulled from AWS. Next, you define the
spec of how this application image is used in AWS.

The `production_ecs` job fails because ECS Cluster is not connected yet. You can fix this
later.

### Create an ECS task definition

[ECS Task definitions](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definitions.html)
is a specification about how the application image is started by an [ECS service](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html).

1. Go to **ECS > Task Definitions** on [AWS console](https://aws.amazon.com/).
1. Select **Create new Task Definition**.

   ![The task definitions page.](img/ecs-task-definitions_v13_10.png)

1. Choose **EC2** as the launch type. Select **Next Step**.
1. Set `ecs_demo` to **Task Definition Name**.
1. Set `512` to **Task Size > Task memory** and **Task CPU**.
1. Select **Container Definitions > Add container**. This opens a container registration form.
1. Set `web` to **Container name**.
1. Set `registry.gitlab.com/<your-namespace>/ecs-demo/master:latest` to **Image**.
   Alternatively, you can copy and paste the image path from the [GitLab container registry page](#push-a-containerized-application-image-to-gitlab-container-registry).

   ![Completed container name and image fields.](img/container-name_v13_10.png)

1. Add a port mapping. Set `80` to **Host Port** and `5000` to **Container port**.

   ![A container port mappings entry.](img/container-port-mapping_v13_10.png)

1. Select **Create**.

Now you have the initial task definition. Next, you create an actual infrastructure to run the
application image.

### Create an ECS cluster

An [ECS cluster](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/clusters.html)
is a virtual group of [ECS services](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html).
It's also associated with EC2 or Fargate as the computation resource.

1. Go to **ECS > Clusters** on [AWS console](https://aws.amazon.com/).
1. Select **Create Cluster**.
1. Select **EC2 Linux + Networking** as the cluster template. Select **Next Step**.
1. Set `ecs-demo` to **Cluster Name**.
1. Choose the default [VPC](https://aws.amazon.com/vpc/?vpc-blogs.sort-by=item.additionalFields.createdDate&vpc-blogs.sort-order=desc)
   in **Networking**. If there are no existing VPCs, you can leave it as-is to create a new one.
1. Set all available subnets of the VPC to **Subnets**.
1. Select **Create**.
1. Make sure that the ECS cluster has been successfully created.

   ![A successfully created ECS cluster](img/ecs-launch-status_v13_10.png)

Now you can register an ECS service to the ECS cluster in the next step.

Note the following:

- Optionally, you can set a SSH key pair in the creation form. This allows you to SSH to the EC2
  instance for debugging.
- If you don't choose an existing VPC, it creates a new VPC by default. This could cause an error if
  it reaches the maximum allowed number of internet gateways on your account.
- The cluster requires an EC2 instance, meaning it costs you [according to the instance-type](https://aws.amazon.com/ec2/pricing/on-demand/).

### Create an ECS Service

[ECS service](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs_services.html)
is a daemon to create an application container based on the [ECS task definition](#create-an-ecs-task-definition).

1. Go to **ECS > Clusters > ecs-demo > Services** on the [AWS console](https://aws.amazon.com/)
1. Select **Deploy**. This opens a service creation form.
1. Select `EC2` in **Launch Type**.
1. Set `ecs_demo` to **Task definition**. This corresponds to [the task definition you created above](#create-an-ecs-task-definition).
1. Set `ecs_demo` to **Service name**.
1. Set `1` to **Desired tasks**.

   ![A completed Services page.](img/service-parameter_v13_10.png)

1. Select **Deploy**.
1. Make sure that the created service is active.

   ![An active service running.](img/service-running_v13_10.png)

The AWS console UI changes from time to time. If you can't find a relevant component in the
instructions, select the closest one.

### View the demo application

Now, the demo application is accessible from the internet.

1. Go to **EC2 > Instances** on the [AWS console](https://aws.amazon.com/)
1. Search by `ECS Instance` to find the corresponding EC2 instance that [the ECS cluster created](#create-an-ecs-cluster).
1. Select the ID of the EC2 instance. This brings you to the instance detail page.
1. Copy **Public IPv4 address** and paste it in the browser. Now you can see the demo application
   running.

   ![The demo application running in a browser.](img/view-running-app_v13_10.png)

In this guide, HTTPS/SSL is **not** configured. You can access to the application through HTTP only
(for example, `http://<ec2-ipv4-address>`).

## Set up Continuous Deployment from GitLab

Now that you have an application running on ECS, you can set up continuous deployment from GitLab.

### Create a new IAM user as a deployer

For GitLab to access the ECS cluster, service, and task definition that you created above, You must
create a deployer user on AWS:

1. Go to **IAM > Users** on [AWS console](https://aws.amazon.com/).
1. Select **Add user**.
1. Set `ecs_demo` to **User name**.
1. Enable **Programmatic access** checkbox. Select **Next: Permissions**.
1. Select `Attach existing policies directly` in **Set permissions**.
1. Select `AmazonECS_FullAccess` from the policy list. Select **Next: Tags** and **Next: Review**.

   ![A selected `AmazonECS_FullAccess` policy.](img/ecs-policy_v13_10.png)

1. Select **Create user**.
1. Take note of the **Access key ID** and **Secret access key** of the created user.

NOTE:
Do not share the secret access key in a public place. You must save it in a secure place.

### Setup credentials in GitLab to let pipeline jobs access to ECS

You can register the access information in [GitLab CI/CD Variables](../../variables/_index.md).
These variables are injected into the pipeline jobs and can access the ECS API.

1. On the left sidebar, select **Search or go to** and find your `ecs-demo` project.
1. Go to **Settings > CI/CD > Variables**.
1. Select **Add Variable** and set the following key-value pairs.

   | Key                          | Value                                 | Note |
   |------------------------------|---------------------------------------|------|
   | `AWS_ACCESS_KEY_ID`          | `<Access key ID of the deployer>`     | For authenticating `aws` CLI. |
   | `AWS_SECRET_ACCESS_KEY`      | `<Secret access key of the deployer>` | For authenticating `aws` CLI. |
   | `AWS_DEFAULT_REGION`         | `us-east-2`                           | For authenticating `aws` CLI. |
   | `CI_AWS_ECS_CLUSTER`         | `ecs-demo`                            | The ECS cluster is accessed by `production_ecs` job. |
   | `CI_AWS_ECS_SERVICE`         | `ecs_demo`                            | The ECS service of the cluster is updated by `production_ecs` job. Ensure that this variable is scoped to the appropriate environment (`production`, `staging`, `review/*`). |
   | `CI_AWS_ECS_TASK_DEFINITION` | `ecs_demo`                            | The ECS task definition is updated by `production_ecs` job. |

### Make a change to the demo application

Change a file in the project and see if it's reflected in the demo application on ECS:

1. On the left sidebar, select **Search or go to** and find your `ecs-demo` project.
1. Open the `app/views/welcome/index.html.erb` file.
1. Select **Edit**.
1. Change the text to `You're on ECS!`.
1. Select **Commit Changes**. This automatically triggers a new pipeline. Wait until it finishes.
1. [Access the running application on the ECS cluster](#view-the-demo-application). You should see
   this:

   ![A "You're on ECS!" message from a running application.](img/view-running-app-2_v13_10.png)

Congratulations! You successfully set up continuous deployment to ECS.

NOTE:
ECS deploy jobs wait for the rollout to complete before exiting. To disable this behavior,
set `CI_AWS_ECS_WAIT_FOR_ROLLOUT_COMPLETE_DISABLED` to a non-empty value.

## Set up review apps

To use [review apps](../../../development/testing_guide/review_apps.md) with ECS:

1. Set up a new [service](#create-an-ecs-service).
1. Use the `CI_AWS_ECS_SERVICE` variable to set the name.
1. Set the environment scope to `review/*`.

Only one Review App at a time can be deployed because this service is shared by all review apps.

## Set up Security Testing

### Configure SAST

To use [SAST](../../../user/application_security/sast/_index.md) with ECS, add the following to your `.gitlab-ci.yml` file:

```yaml
include:
   - template: Jobs/SAST.gitlab-ci.yml
```

For more details and configuration options, see the [SAST documentation](../../../user/application_security/sast/_index.md#configuration).

### Configure DAST

To use [DAST](../../../user/application_security/dast/_index.md) on non-default branches, [set up review apps](#set-up-review-apps)
and add the following to your `.gitlab-ci.yml` file:

```yaml
include:
  - template: Security/DAST.gitlab-ci.yml
```

To use DAST on the default branch:

1. Set up a new [service](#create-an-ecs-service). This service will be used to deploy a temporary
   DAST environment.
1. Use the `CI_AWS_ECS_SERVICE` variable to set the name.
1. Set the scope to the `dast-default` environment.
1. Add the following to your `.gitlab-ci.yml` file:

```yaml
include:
  - template: Security/DAST.gitlab-ci.yml
  - template: Jobs/DAST-Default-Branch-Deploy.gitlab-ci.yml
```

For more details and configuration options, see the [DAST documentation](../../../user/application_security/dast/_index.md).

## Further reading

- If you're interested in more of the continuous deployments to clouds, see [cloud deployments](../_index.md).
- If you want to quickly set up DevSecOps in your project, see [Auto DevOps](../../../topics/autodevops/_index.md).
- If you want to quickly set up the production-grade environment, see [the 5 Minute Production App](https://gitlab.com/gitlab-org/5-minute-production-app/deploy-template/-/blob/master/README.md).
