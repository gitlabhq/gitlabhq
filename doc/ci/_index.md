---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Build and test your application.
title: Get started with GitLab CI/CD
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

CI/CD is a continuous method of software development, where you continuously build,
test, deploy, and monitor iterative code changes.

This iterative process helps reduce the chance that you develop new code based on
buggy or failed previous versions. GitLab CI/CD can catch bugs early in the development cycle,
and help ensure that the code deployed to production complies with your established code standards.

This process is part of a larger workflow:

![GitLab DevSecOps lifecycle with stages for Plan, Create, Verify, Secure, Release, and Monitor.](img/get_started_cicd_v16_11.png)

## Step 1: Configure your pipeline

To use GitLab CI/CD, you start with a `.gitlab-ci.yml` file at the root of your project.
This file specifies the stages, jobs, and scripts to be executed during your CI/CD pipeline.
It is a YAML file with its own custom syntax.

By default, the file is named `.gitlab-ci.yml`, but you can use any filename.

In this file, you define variables, dependencies between jobs, and specify when
and how each job should be executed.

A pipeline is defined in the `.gitlab-ci.yml` file,
and executes when the file runs on a runner.

Pipelines are made up of stages and jobs:

- Stages define the order of execution. Typical stages might be `build`, `test`, and `deploy`.
- Jobs specify the tasks to be performed in each stage. For example, a job can compile or test code.

Pipelines can be triggered by various events, like commits or merges, or can be on schedule.
In your pipeline, you can integrate with a wide range of tools and platforms.

For more information, see:

- [Tutorial: Create and run your first GitLab CI/CD pipeline](quick_start/_index.md)
- [Pipelines](pipelines/_index.md)

## Step 2: Find or create runners

Runners are the agents that run your jobs. These agents can run on physical machines or virtual instances.
In your `.gitlab-ci.yml` file, you can specify a container image you want to use when running the job.
The runner loads the image, clones your project, and runs the job either locally or in the container.

If you use GitLab.com, runners on Linux, Windows, and macOS are already available for use.
If needed, you can also register your own runners.

If you don't use GitLab.com, you can:

- Register runners or use runners already registered for your GitLab Self-Managed instance.
- Create a runner on your local machine.

For more information, see:

- [Create, register, and run your own project runner](../tutorials/create_register_first_runner/_index.md)

## Step 3: Use CI/CD variables and expressions

GitLab CI/CD variables are key-value pairs you use to store and pass configuration settings
and sensitive information, like passwords or API keys, to jobs in a pipeline.

GitLab CI/CD expressions allow you to inject data dynamically into your pipeline configuration.
The data available depends on the expression context.
For example, the `inputs` context allows you to access information passed into the
configuration file from a parent file or when a pipeline is run.

### CI/CD variables

Use CI/CD variables to customize jobs by making values defined elsewhere accessible to jobs.
You can hard-code CI/CD variables in your `.gitlab-ci.yml` file, set them in your project settings,
or generate them dynamically. You can define them for the project, group, or instance.

The following types of variables are available:

- Custom variables: Variables that you create and manage in the UI, API, or configuration files.
- Predefined variables: Variables that GitLab automatically sets to provide information about the current job, pipeline, and environment.

You can configure variables with security settings:

- Protected variables: Restrict access to jobs running on protected branches or tags.
- Masked variables: Hide variable values in job logs to prevent sensitive information from being exposed.

For more information, see:

- [CI/CD variables](variables/_index.md)

### CI/CD expressions

CI/CD expressions use the `$[[ ]]` syntax and are validated when you create a pipeline.
You can also validate expressions in the pipeline editor before committing changes.

Expressions enable dynamic configuration based on different contexts:

- **Inputs context** (`$[[ inputs.INPUT_NAME ]]`): Access typed parameters passed into configuration files with `include:inputs` or when a new pipeline is run
- **Matrix context** (`$[[ matrix.IDENTIFIER ]]`): Access matrix values in job dependencies to create 1:1 mappings between matrix jobs

For more information, see:

- [CI expressions](yaml/expressions.md)

## Step 4: Use CI/CD components

A CI/CD component is a reusable pipeline configuration unit.
Use a CI/CD component to compose an entire pipeline configuration or a small part of a larger pipeline.

You can add a component to your pipeline configuration with `include:component`.

Reusable components help reduce duplication, improve maintainability, and promote consistency across projects.
Create a component project and publish it to the CI/CD Catalog to share your component across multiple projects.

GitLab also has CI/CD component templates for common tasks and integrations.

For more information, see:

- [CI/CD components](components/_index.md)
