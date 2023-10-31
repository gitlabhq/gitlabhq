---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Learn how to use GitLab CI/CD, the GitLab built-in Continuous Integration, Continuous Deployment, and Continuous Delivery toolset to build, test, and deploy your application."
type: index
---

# Get started with GitLab CI/CD **(FREE ALL)**

CI/CD is a continuous method of software development, where you continuously build,
test, deploy, and monitor iterative code changes.

This iterative process helps reduce the chance that you develop new code based on
buggy or failed previous versions. GitLab CI/CD can catch bugs early in the development cycle,
and help ensure that all the code deployed to production complies with your established code standards.

## Common terms

If you're new to GitLab CI/CD, start by reviewing some of the commonly used terms.

### The `.gitlab-ci.yml` file

To use GitLab CI/CD, you start with a `.gitlab-ci.yml` file at the root of your project
which contains the configuration for your CI/CD pipeline. This file follows the YAML format
and has its own special syntax.

You can name this file anything you want, but `.gitlab-ci.yml` is the most common name.

In the `.gitlab-ci.yml` file, you can define:

- The tasks you want to complete, for example test and deploy your application.
- Other configuration files and templates you want to include.
- Dependencies and caches.
- The commands you want to run in sequence and those you want to run in parallel.
- The location to deploy your application to.
- Whether you want to run the scripts automatically or trigger any of them manually.

**Get started:**

- [Create your first `.gitlab-ci.yml` file](quick_start/index.md).
- [View all the possible keywords that you can use in the `.gitlab-ci.yml` file](yaml/index.md).
the configuration.
- Use the [pipeline editor](pipeline_editor/index.md) to edit or [visualize](pipeline_editor/index.md#visualize-ci-configuration)
  your CI/CD configuration.

### Runners

Runners are the agents that run your jobs. These agents can run on physical machines or virtual instances.
In your `.gitlab-ci.yml` file, you can specify a container image you want to use when running the job.
The runner loads the image and runs the job either locally or in the container.

If you use GitLab.com, SaaS runners on Linux, Windows, and macOS are already available for use. And you can register your own
runners on GitLab.com if you'd like.

If you don't use GitLab.com, you can:

- Register runners or use runners already registered for your self-managed instance.
- Create a runner on your local machine.

**Get started:**

- [Create a runner on your local machine](../tutorials/create_register_first_runner/index.md).
- [Learn more about runners](https://docs.gitlab.com/runner/).

### Pipelines

Pipelines are made up of jobs and stages:

- **Jobs** define what you want to do. For example, test code changes, or deploy
  to a staging environment.
- Jobs are grouped into **stages**. Each stage contains at least one job.
  Typical stages might be `build`, `test`, and `deploy`.

**Get started:**

- [Learn more about pipelines](pipelines/index.md).

### CI/CD variables

CI/CD variables help you customize jobs by making values defined elsewhere accessible to jobs.
They can be hard-coded in your `.gitlab-ci.yml` file, project settings, or dynamically generated
[predefined variables](variables/predefined_variables.md).

**Get started:**

- [Learn more about CI/CD variables](variables/index.md).

### CI/CD components

A [CI/CD component](components/index.md) is a reusable single pipeline configuration unit. Use them to compose an entire pipeline configuration or a small part of a larger pipeline.

## Disable GitLab CI/CD in a project

GitLab CI/CD is enabled by default on all new projects. If you use an external CI/CD server like
Jenkins or Drone CI, you can disable GitLab CI/CD to avoid conflicts with the commits status API.

You can disable GitLab CI/CD per project or [for all new projects on an instance](../administration/cicd.md).

When you disable GitLab CI/CD:

- The **CI/CD** item in the left sidebar is removed.
- The `/pipelines` and `/jobs` pages are no longer available.
- Existing jobs and pipelines are hidden, not removed.

To disable GitLab CI/CD in your project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. In the **Repository** section, turn off **CI/CD**.
1. Select **Save changes**.

These changes do not apply to projects in an [external integration](../user/project/integrations/index.md#available-integrations).

## Videos

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [GitLab CI/CD demo](https://www.youtube-nocookie.com/embed/ljth1Q5oJoo).
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [GitLab CI/CD and the Web IDE](https://youtu.be/l5705U8s_nQ?t=369).
- Webcast: [Mastering continuous software development](https://about.gitlab.com/webcast/mastering-ci-cd/).

## Related topics

- [Five teams that made the switch to GitLab CI/CD](https://about.gitlab.com/blog/2019/04/25/5-teams-that-made-the-switch-to-gitlab-ci-cd/).
- [Make the case for CI/CD in your organization](https://about.gitlab.com/why-gitlab/).
- Learn how [Verizon reduced rebuilds](https://about.gitlab.com/blog/2019/02/14/verizon-customer-story/) from 30 days to under 8 hours with GitLab.
- Use the [GitLab Workflow VS Code extension](../user/project/repository/vscode.md) to
  [validate your configuration](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#validate-gitlab-ci-configuration)
  and [view your pipeline status](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow#information-about-your-branch-pipelines-mr-closing-issue).
