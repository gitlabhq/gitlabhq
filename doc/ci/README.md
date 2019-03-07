---
comments: false
description: "Learn how to use GitLab CI/CD, the GitLab built-in Continuous Integration, Continuous Deployment, and Continuous Delivery toolset to build, test, and deploy your application."
---

# GitLab Continuous Integration (GitLab CI/CD)

**GitLab CI/CD** is GitLab's built-in tool for software development using the Continuous Methodology (Continuous Integration, Continuous Delivery, Continuous Deployment).

## Overview

CI/CD is a vast area, so GitLab provides documentation for all levels of expertise. Consult the following table to find the right documentation for you:

| Level of expertise                  | Resource                                                                                                                                              |
|:------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------|
| New to the concepts of CI and CD    | For a high-level overview, read an [introduction to CI/CD with GitLab](introduction/index.md). |
| Familiar with GitLab CI/CD concepts | After getting familiar with GitLab CI/CD, let us walk you through a simple example in our [quick start guide](quick_start/README.md).                 |
| A GitLab CI/CD expert               | Jump straight to our [`.gitlab.yml`](yaml/README.md) reference.                                                                                       |

NOTE: **Note:**
Within the [DevOps lifecycle](../README.md#the-entire-devops-lifecycle), GitLab CI/CD spans
the [Verify (CI)](../README.md#verify) and [Release (CD)](../README.md#release) stages.

## Essentials

The following documentation provides the minimum required knowledge for making use of GitLab CI/CD:

| Topic                                                                   | Description                                              |
|:------------------------------------------------------------------------|:---------------------------------------------------------|
| [Getting started with GitLab CI/CD](quick_start/README.md)              | Outlines the first steps for configuring GitLab CI/CD.   |
| [Introduction to pipelines and jobs](pipelines.md)                      | Provides an overview of GitLab CI/CD and jobs.           |
| [Configuration of your pipelines with `.gitlab-ci.yml`](yaml/README.md) | A comprehensive reference for the `.gitlab-ci.yml` file. |
| [`.gitlab-ci.yml` introduction](../user/project/pages/getting_started_part_four.md)                            | A step-by-step introduction to writing a GitLab CI/CD configuration file (`.gitlab-ci.yml`) for the first time. |

NOTE: **Note:**
Familiarity with [GitLab Runner](https://docs.gitlab.com/runner/) is useful because it is
responsible for running the jobs in your CI/CD pipeline. On GitLab.com, shared Runners are enabled
by default so you don't need to set up anything to get started.

### Auto DevOps

An alternative to manually configuring CI/CD, GitLab supports [Auto DevOps](../topics/autodevops/index.md),
which:

- Provides simplified setup and execution of CI/CD.
- Allows GitLab to automatically detect, build, test, deploy, and monitor your applications.

## Basic usage

With basic knowledge of how GitLab CI/CD works, the following documentation extends your knowledge
into more features:

| Topic                                                                                                  | Description                                                                      |
|:-------------------------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------|
| [CI/CD Variables](variables/README.md)                                                                 | How environment variables can be configured and made available in pipelines.     |
| [Where variables can be used](variables/where_variables_can_be_used.md)                                | A deeper look into where and how CI/CD variables can be used.                    |
| [User](../user/permissions.md#gitlab-ci) and [job](../user/permissions.md#job-permissions) permissions | Learn about the access levels a user can have for performing certain CI actions. |
| [Configuring GitLab Runners](runners/README.md)                                                        | Documentation for configuring [GitLab Runner](https://docs.gitlab.com/runner/).  |

## Advanced usage

Once you get familiar with the basics of GitLab CI/CD, consult the following documentation to make
use of advanced features:

| Topic                                                                            | Description                                                                                                                  |
|:---------------------------------------------------------------------------------|:-----------------------------------------------------------------------------------------------------------------------------|
| [Introduction to environments and deployments](environments.md)                  | Learn how to separate your jobs into environments and use them for different purposes like testing, building and, deploying. |
| [Job artifacts](../user/project/pipelines/job_artifacts.md)                      | Learn about the output of jobs.                                                                                              |
| [Cache dependencies in GitLab CI/CD](caching/index.md)                           | Discover how to speed up pipelines using caching.                                                                            |
| [Using Git submodules with GitLab CI](git_submodules.md)                         | How to run your CI jobs when using Git submodules.                                                                           |
| [Pipelines for merge requests](merge_request_pipelines/index.md)                 | Create pipelines specifically for merge requests.                                                                            |
| [Using SSH keys with GitLab CI/CD](ssh_keys/README.md)                           | Use SSH keys in your build environment.                                                                                      |
| [Triggering pipelines through the API](triggers/README.md)                       | Use the GitLab API to trigger a pipeline.                                                                                    |
| [Pipeline schedules](../user/project/pipelines/schedules.md)                     | Trigger pipelines on a schedule.                                                                                             |
| [Connecting GitLab with a Kubernetes cluster](../user/project/clusters/index.md) | Integrate one or more Kubernetes clusters to your project.                                                                   |
| [ChatOps](chatops/README.md)                                                     | Trigger CI jobs from chat, with results sent back to the channel.                                                            |
| [Interactive web terminals](interactive_web_terminal/index.md)                   | Open an interactive web terminal to debug the running jobs.                                                                  |

### GitLab Pages

GitLab CI/CD can be used to build and host static websites. For more information, see the
documentation on [GitLab Pages](../user/project/pages/index.md),
or dive right into the [CI/CD step-by-step guide for Pages](../user/project/pages/getting_started_part_four.md).

## Examples

Check out the [GitLab CI/CD examples](examples/README.md) for a collection of tutorials and guides on
setting up your CI/CD pipeline for various programming languages, frameworks, and operating systems.

## Administration

As a GitLab administrator, you can change the default behavior of GitLab CI/CD for:

- An [entire GitLab instance](../user/admin_area/settings/continuous_integration.md).
- Specific projects, using [pipelines settings](../user/project/pipelines/settings.md).

See also:

- [How to enable or disable GitLab CI/CD](enable_or_disable_ci.md).
- Other [CI administration settings](../administration/index.md#continuous-integration-settings).

## Using Docker

Docker is commonly used with GitLab CI/CD. Learn more about how to to accomplish this with the following
documentation:

| Topic                                                                    | Description                                                              |
|:-------------------------------------------------------------------------|:-------------------------------------------------------------------------|
| [Using Docker images](docker/using_docker_images.md)                     | Use GitLab and GitLab Runner with Docker to build and test applications. |
| [Building Docker images with GitLab CI/CD](docker/using_docker_build.md) | Maintain Docker-based projects using GitLab CI/CD.                       |

Related topics include:

- [Docker integration](docker/README.md).
- [CI services (linked Docker containers)](services/README.md).
- [Setting up GitLab Runner For Continuous Integration](https://about.gitlab.com/2016/03/01/gitlab-runner-with-docker/) (article).

## Further resources

This section provides further resources to help you get familiar with GitLab CI/CD.

### Articles

The following table provides a list of articles about CI/CD, sorted in reverse chronological order of publish date:

| Publish Date | Article                                                                                                                                                                                                                                       |
|:-------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 2017-07-13   | [Making CI easier with GitLab](https://about.gitlab.com/2017/07/13/making-ci-easier-with-gitlab/).                                                                                                                                            |
| 2017-05-22   | [Fast and natural continuous integration with GitLab CI](https://about.gitlab.com/2017/05/22/fast-and-natural-continuous-integration-with-gitlab-ci/).                                                                                        |
| 2016-11-22   | [Introducing Review Apps](https://about.gitlab.com/2016/11/22/introducing-review-apps/).                                                                                                                                                      |
| 2016-08-26   | [GitLab CI: Deployment & Environments](https://about.gitlab.com/2016/08/26/ci-deployment-and-environments/).                                                                                                                                  |
| 2016-08-05   | [Continuous Integration, Delivery, and Deployment with GitLab](https://about.gitlab.com/2016/08/05/continuous-integration-delivery-and-deployment-with-gitlab/).                                                                              |
| 2016-07-29   | [GitLab CI: Run jobs sequentially, in parallel or build a custom pipeline](https://about.gitlab.com/2016/07/29/the-basics-of-gitlab-ci/).                                                                                                     |
| 2016-06-09   | [Continuous Delivery with GitLab and Convox](https://about.gitlab.com/2016/06/09/continuous-delivery-with-gitlab-and-convox/)                                                                                                                 |
| 2016-05-23   | [GitLab Container Registry](https://about.gitlab.com/2016/05/23/gitlab-container-registry/).                                                                                                                                                  |
| 2016-05-05   | [Getting Started with GitLab and Shippable Continuous Integration](https://about.gitlab.com/2016/05/05/getting-started-gitlab-and-shippable/)                                                                                                 |
| 2016-04-19   | [GitLab Partners with DigitalOcean to make Continuous Integration faster, safer, and more affordable](https://about.gitlab.com/2016/04/19/gitlab-partners-with-digitalocean-to-make-continuous-integration-faster-safer-and-more-affordable/) |
| 2015-03-01   | [Setting up GitLab Runner For Continuous Integration](https://about.gitlab.com/2016/03/01/gitlab-runner-with-docker/).                                                                                                                        |
| 2015-12-14   | [Getting started with GitLab and GitLab CI](https://about.gitlab.com/2015/12/14/getting-started-with-gitlab-and-gitlab-ci/).                                                                                                                  |

### Videos

The following table provides a list of videos about CI/CD, sorted in reverse chronological order of publish date:

| Publish Date | Video                                                                                                                                                              |
|:-------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 2017-07-17   | [GitLab CI/CD Deep Dive](https://youtu.be/pBe4t1CD8Fc?t=195).                                                                                                      |
| 2017-03-13   | [Demo: CI/CD with GitLab in action](https://about.gitlab.com/2017/03/13/ci-cd-demo/).                                                                              |
| 2016-04-20   | [Webcast Recording and Slides: Getting started with CI in GitLab](https://about.gitlab.com/2016/04/20/webcast-recording-and-slides-introduction-to-ci-in-gitlab/). |

In addition, the following third-party videos are available:

- [Intégration continue avec GitLab (September 2016)](https://www.youtube.com/watch?v=URcMBXjIr24&t=13s).
- [GitLab CI for Minecraft Plugins (July 2016)](https://www.youtube.com/watch?v=Z4pcI9F8yf8).

### Example Projects

[`review-apps-nginx`](https://gitlab.com/gitlab-examples/review-apps-nginx/) provides an example of using Review Apps.

Other example projects are available at the [`gitlab-examples`](https://gitlab.com/gitlab-examples) group.

### Why GitLab CI/CD?

The following articles explain reasons why you might use GitLab CI/CD for your CI/CD infrastructure:

- [Why we chose GitLab CI for our CI/CD solution](https://about.gitlab.com/2016/10/17/gitlab-ci-oohlala/).
- [Building our web-app on GitLab CI](https://about.gitlab.com/2016/07/22/building-our-web-app-on-gitlab-ci/).

See also the [Why CI/CD?](https://docs.google.com/presentation/d/1OGgk2Tcxbpl7DJaIOzCX4Vqg3dlwfELC3u2jEeCBbDk) presentation.

## Breaking changes

As GitLab CI/CD has evolved, certain breaking changes have been necessary. These are:

- [CI variables renaming for GitLab 9.0](variables/README.md#gitlab-90-renaming). Read about the
  deprecated CI variables and what you should use for GitLab 9.0+.
- [New CI job permissions model](../user/project/new_ci_build_permissions_model.md).
  See what changed in GitLab 8.12 and how that affects your jobs.
  There's a new way to access your Git submodules and LFS objects in jobs.
