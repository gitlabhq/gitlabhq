---
stage: none
group: Tutorials
info: For assistance with this tutorials page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments-to-other-projects-and-subjects.
description: CI/CD fundamentals and examples.
title: 'Tutorials: Build your application'
---

## Learn about CI/CD pipelines

Use CI/CD pipelines to automatically build, test, and deploy your code.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [Create and run your first GitLab CI/CD pipeline](../ci/quick_start/_index.md) | Create a `.gitlab-ci.yml` file and start a pipeline. | {{< icon name="star" >}} |
| [Create a complex pipeline](../ci/quick_start/tutorial.md) | Learn about the most commonly used GitLab CI/CD keywords by building an increasingly complex pipeline. |  |
| <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Get started: Learn about CI/CD](https://www.youtube.com/watch?v=sIegJaLy2ug) (9m 02s) | Learn about the `.gitlab-ci.yml` file and how it's used. | {{< icon name="star" >}} |
| [GitLab CI Fundamentals](https://university.gitlab.com/learn/learning-path/gitlab-ci-fundamentals) | Learn about GitLab CI/CD and build a pipeline in this self-paced course. | {{< icon name="star" >}} |
| <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [CI deep dive](https://www.youtube.com/watch?v=ZVUbmVac-m8&list=PL05JrBw4t0KorkxIFgZGnzzxjZRCGROt_&index=27) (22m 51s) | Take a closer look at pipelines and continuous integration concepts. | |
| [Set up CI/CD in the cloud](../ci/examples/_index.md#cicd-in-the-cloud) | Learn how to set up CI/CD in different cloud-based environments. | |
| [Create a GitLab pipeline to push to Google Artifact Registry](create_gitlab_pipeline_push_to_google_artifact_registry/_index.md) | Learn how to connect GitLab to Google Cloud and create a pipeline to push images to Artifact Registry. | |
| [Find CI/CD examples and templates](../ci/examples/_index.md#cicd-examples)  | Use these examples and templates to set up CI/CD for your use case. | |
| <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Understand CI/CD rules](https://www.youtube.com/watch?v=QjQc-zeL16Q) (8m 56s) |  Learn more about how to use CI/CD rules. | |
| [Use Auto DevOps to deploy an application](../topics/autodevops/cloud_deployments/auto_devops_with_gke.md)  | Deploy an application to Google Kubernetes Engine (GKE). | |
| [Using Buildah in a rootless container with GitLab Runner Operator on OpenShift](../ci/docker/buildah_rootless_tutorial.md)  | Learn how to set up GitLab Runner Operator on OpenShift to build Docker images with Buildah in a rootless container | |
| [Set up CI/CD steps](setup_steps/_index.md)  | Learn how to set up the steps component and configure a CI/CD pipeline to use the step in a job. | |

## Configure GitLab Runner

Set up runners to run jobs in a pipeline.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [Create, register, and run your own project runner](create_register_first_runner/_index.md) | Learn the basics of how to create and register a project runner that runs jobs for your project. | {{< icon name="star" >}} |
| [Configure GitLab Runner to use the Google Kubernetes Engine](configure_gitlab_runner_to_use_gke/_index.md) | Learn how to configure GitLab Runner to use the GKE to run jobs. | |
| [Automate runner creation and registration](automate_runner_creation/_index.md) | Learn how to automate runner creation as an authenticated user to optimize your runner fleet.  | |
| [Set up the Google Cloud integration](set_up_gitlab_google_integration/_index.md) | Learn how to integrate Google Cloud with GitLab and set up GitLab Runner to run jobs on Google Cloud.  | |

## Use Mobile DevOps tools

Build, sign, and release mobile apps for Android and iOS.

| Topic | Description | Good for beginners |
|-------|-------------|--------------------|
| [Build Android apps with GitLab Mobile DevOps](../ci/mobile_devops/mobile_devops_tutorial_android.md) | Learn how to use a CI/CD pipeline to build your Android mobile app. | |
| [Build iOS apps with GitLab Mobile DevOps](../ci/mobile_devops/mobile_devops_tutorial_ios.md) | Learn how to use a CI/CD pipeline to build your iOS mobile app. | |
