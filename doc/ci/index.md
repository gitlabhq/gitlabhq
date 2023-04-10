---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Learn how to use GitLab CI/CD, the GitLab built-in Continuous Integration, Continuous Deployment, and Continuous Delivery toolset to build, test, and deploy your application."
type: index
---

# GitLab CI/CD **(FREE)**

GitLab CI/CD is a tool for software development using the continuous methodologies:

- [Continuous Integration (CI)](introduction/index.md#continuous-integration)
- [Continuous Delivery (CD)](introduction/index.md#continuous-delivery)
- [Continuous Deployment (CD)](introduction/index.md#continuous-deployment)

NOTE:
Out-of-the-box management systems can decrease hours spent on maintaining toolchains by 10% or more.
Watch our ["Mastering continuous software development"](https://about.gitlab.com/webcast/mastering-ci-cd/)
webcast to learn about continuous methods and how GitLab CI/CD can help you simplify and scale software development.

Use GitLab CI/CD to catch bugs and errors early in
the development cycle. Ensure that all the code deployed to
production complies with the code standards you established for
your app.

GitLab CI/CD can automatically build, test, deploy, and
monitor your applications by using [Auto DevOps](../topics/autodevops/index.md).

For a complete overview of these methodologies and GitLab CI/CD,
read the [Introduction to CI/CD with GitLab](introduction/index.md).

<div class="video-fallback">
  Video demonstration of continuous integration with GitLab CI/CD: <a href="https://www.youtube.com/watch?v=ljth1Q5oJoo">Continuous Integration with GitLab (overview demo)</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/ljth1Q5oJoo" frameborder="0" allowfullscreen> </iframe>
</figure>

## Concepts

GitLab CI/CD uses a number of concepts to describe and run your build and deploy.

| Concept                                                 | Description                                                                           |
|:--------------------------------------------------------|:--------------------------------------------------------------------------------------|
| [Pipelines](pipelines/index.md)                         | Structure your CI/CD process through pipelines.                                       |
| [CI/CD variables](variables/index.md)                   | Reuse values based on a variable/value key pair.                                      |
| [Environments](environments/index.md)                   | Deploy your application to different environments (for example, staging, production). |
| [Job artifacts](jobs/job_artifacts.md)             | Output, use, and reuse job artifacts.                                                 |
| [Cache dependencies](caching/index.md)                  | Cache your dependencies for a faster execution.                                       |
| [GitLab Runner](https://docs.gitlab.com/runner/)        | Configure your own runners to execute your scripts.                                   |
| [Pipeline efficiency](pipelines/pipeline_efficiency.md) | Configure your pipelines to run quickly and efficiently.                              |
| [Test cases](test_cases/index.md)                       | Create testing scenarios.                                                             |

## Configuration

GitLab CI/CD supports numerous configuration options:

| Configuration                                                                                      | Description                                                                               |
|:---------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------------------|
| [Schedule pipelines](pipelines/schedules.md)                                                       | Schedule pipelines to run as often as you need.                                           |
| [Custom path for `.gitlab-ci.yml`](pipelines/settings.md#specify-a-custom-cicd-configuration-file) | Define a custom path for the CI/CD configuration file.                                    |
| [Git submodules for CI/CD](git_submodules.md)                                                      | Configure jobs for using Git submodules.                                                  |
| [SSH keys for CI/CD](ssh_keys/index.md)                                                            | Using SSH keys in your CI pipelines.                                                      |
| [Pipeline triggers](triggers/index.md)                                                             | Trigger pipelines through the API.                                                        |
| [Merge request pipelines](pipelines/merge_request_pipelines.md)                                    | Design a pipeline structure for running a pipeline in merge requests.                     |
| [Integrate with Kubernetes clusters](../user/infrastructure/clusters/index.md)                     | Connect your project to Google Kubernetes Engine (GKE) or an existing Kubernetes cluster. |
| [Optimize GitLab and GitLab Runner for large repositories](large_repositories/index.md)            | Recommended strategies for handling large repositories.                                   |
| [`.gitlab-ci.yml` full reference](yaml/index.md)                                                   | All the attributes you can use with GitLab CI/CD.                                         |

Certain operations can only be performed according to the
[user](../user/permissions.md#gitlab-cicd-permissions) and [job](../user/permissions.md#job-permissions) permissions.

## Features

GitLab CI/CD features, grouped by DevOps stage, include:

| Feature                                                                                      | Description |
|:---------------------------------------------------------------------------------------------|:------------|
| **Configure**                                                                                |             |
| [Auto DevOps](../topics/autodevops/index.md)                                                 | Set up your app's entire lifecycle. |
| [ChatOps](chatops/index.md)                                                                  | Trigger CI jobs from chat, with results sent back to the channel. |
| [Connect to cloud services](cloud_services/index.md)                                         | Connect to cloud providers using OpenID Connect (OIDC) to retrieve temporary credentials to access services or secrets. |
| **Verify**                                                                                   |             |
| [Browser Performance Testing](testing/browser_performance_testing.md)                        | Quickly determine the browser performance impact of pending code changes. |
| [Load Performance Testing](testing/load_performance_testing.md)                              | Quickly determine the server performance impact of pending code changes. |
| [CI services](services/index.md)                                                             | Link Docker containers with your base image. |
| [GitLab CI/CD for external repositories](ci_cd_for_external_repos/index.md)                  | Get the benefits of GitLab CI/CD combined with repositories in GitHub and Bitbucket Cloud. |
| [Interactive Web Terminals](interactive_web_terminal/index.md)                               | Open an interactive web terminal to debug the running jobs. |
| [Review Apps](review_apps/index.md)                                                          | Configure GitLab CI/CD to preview code changes. |
| [Unit test reports](testing/unit_test_reports.md)                                            | Identify test failures directly on merge requests. |
| [Using Docker images](docker/using_docker_images.md)                                         | Use GitLab and GitLab Runner with Docker to build and test applications. |
| **Release**                                                                                  |             |
| [Auto Deploy](../topics/autodevops/stages.md#auto-deploy)                                    | Deploy your application to a production environment in a Kubernetes cluster. |
| [Building Docker images](docker/using_docker_build.md)                                       | Maintain Docker-based projects using GitLab CI/CD. |
| [Canary Deployments](../user/project/canary_deployments.md)                                  | Ship features to only a portion of your pods and let a percentage of your user base to visit the temporarily deployed feature. |
| [Deploy boards](../user/project/deploy_boards.md)                                            | Check the current health and status of each CI/CD environment running on Kubernetes. |
| [Feature flags](../operations/feature_flags.md)                                              | Deploy your features behind Feature flags. |
| [GitLab Pages](../user/project/pages/index.md)                                               | Deploy static websites. |
| [GitLab Releases](../user/project/releases/index.md)                                         | Add release notes to Git tags. |
| [Cloud deployment](cloud_deployment/index.md)                                                | Deploy your application to a main cloud provider. |
| **Secure**                                                                                   |             |
| [Code Quality](testing/code_quality.md)                                                      | Analyze your source code quality. |
| [Container Scanning](../user/application_security/container_scanning/index.md)               | Check your Docker containers for known vulnerabilities. |
| [Dependency Scanning](../user/application_security/dependency_scanning/index.md)             | Analyze your dependencies for known vulnerabilities. |
| [License Compliance](../user/compliance/license_compliance/index.md)                         | Search your project dependencies for their licenses. |
| [Security Test reports](../user/application_security/index.md)                               | Check for app vulnerabilities. |

## Examples

See the [CI/CD examples](examples/index.md) page for example project code and tutorials for
using GitLab CI/CD with various:

- App frameworks
- Languages
- Platforms

## Administration

You can change the default behavior of GitLab CI/CD for:

- An entire GitLab instance in the [CI/CD administration settings](../administration/cicd.md).
- Specific projects in the [pipelines settings](pipelines/settings.md).

See also:

- [Enable or disable GitLab CI/CD in a project](enable_or_disable_ci.md).

## Related topics

- [Why you might choose GitLab CI/CD](https://about.gitlab.com/blog/2016/10/17/gitlab-ci-oohlala/)
- [Reasons you might migrate from another platform](https://about.gitlab.com/blog/2016/07/22/building-our-web-app-on-gitlab-ci/)
- [Five teams that made the switch to GitLab CI/CD](https://about.gitlab.com/blog/2019/04/25/5-teams-that-made-the-switch-to-gitlab-ci-cd/)
- If you use VS Code to edit your GitLab CI/CD configuration, the
  [GitLab Workflow VS Code extension](../user/project/repository/vscode.md) helps you
  [validate your configuration](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#validate-gitlab-ci-configuration)
  and [view your pipeline status](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#information-about-your-branch-pipelines-mr-closing-issue)

See also the [Why CI/CD?](https://docs.google.com/presentation/d/1OGgk2Tcxbpl7DJaIOzCX4Vqg3dlwfELC3u2jEeCBbDk) presentation.

### Major version changes (breaking)

As GitLab CI/CD has evolved, certain breaking changes have
been necessary.

For GitLab 15.0 and later, all breaking changes are documented on the following pages:

- [Deprecations](../update/deprecations.md)
- [Removals](../update/removals.md)

The breaking changes for [GitLab Runner](https://docs.gitlab.com/runner/) in earlier
major version releases are:

- 14.0: No breaking changes.
- 13.0:
  - [Remove Backported `os.Expand`](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4915).
  - [Remove Fedora 29 package support](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/16158).
  - [Remove macOS 32-bit support](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/25466).
  - [Removed `debug/jobs/list?v=1` endpoint](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/6361).
  - [Remove support for array of strings when defining services for Docker executor](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4922).
  - [Remove `--docker-services` flag on register command](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/6404).
  - [Remove legacy build directory caching](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4180).
  - [Remove `FF_USE_LEGACY_VOLUMES_MOUNTING_ORDER` feature flag](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/6581).
  - [Remove support for Windows Server 1803](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/6553).
- 12.0:
  - [Use `refspec` to clone/fetch Git repository](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4069).
  - [Old cache configuration](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4070).
  - [Old metrics server configuration](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4072).
  - [Remove `FF_K8S_USE_ENTRYPOINT_OVER_COMMAND`](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4073).
  - [Remove Linux distributions that reach EOL](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/1130).
  - [Update command line API for helper images](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4013).
  - [Remove old `git clean` flow](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4175).
