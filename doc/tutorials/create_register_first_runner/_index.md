---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Create, register, and run your own project runner'
---

This tutorial shows you how to configure and run your first runner in GitLab.

A runner is an agent in the GitLab Runner application that runs jobs in a GitLab CI/CD pipeline.
Jobs are defined in the `.gitlab-ci.yml` file and assigned to available runners.

GitLab has three types of runners:

- Shared: Available to all groups and projects in a GitLab instance.
- Group: Available to all projects and subgroups in a group.
- Project: Associated with specific projects. Typically, project runners are used by one project at a time.

For this tutorial, you'll create a project runner to run jobs defined in a basic pipeline
configuration:

1. [Create a blank project](#create-a-blank-project)
1. [Create a project pipeline](#create-a-project-pipeline).
1. [Create and register a project runner](#create-and-register-a-project-runner).
1. [Trigger a pipeline to run your runner](#trigger-a-pipeline-to-run-your-runner).

## Before you begin

Before you can create, register, and run a runner,  [GitLab Runner](https://docs.gitlab.com/runner/install/) must be installed on a local computer.

## Create a blank project

First, create a blank project where you can create your CI/CD pipeline and runner.

To create a blank project:

1. On the left sidebar, at the top, select **Create new** (**{plus}**) and **New project/repository**.
1. Select **Create blank project**.
1. Enter the project details:
   - In the **Project name** field, enter the name of your project. The name must start with a lowercase or uppercase letter (`a-zA-Z`), digit (`0-9`), emoji, or underscore (`_`). It can also contain dots (`.`), pluses (`+`), dashes (`-`), or spaces.
   - In the **Project slug** field, enter the path to your project. The GitLab instance uses the
     slug as the URL path to the project. To change the slug, first enter the project name,
     then change the slug.
1. Select **Create project**.

## Create a project pipeline

Next, create a `.gitlab-ci.yml` file for your project. This is a YAML file where you specify instructions for GitLab CI/CD.

In this file, you define:

- The structure and order of jobs that the runner should execute.
- The decisions the runner should make when specific conditions are encountered.

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Project overview**.
1. Select the plus icon (**{plus}**), then select **New file**.
1. In the **Filename** field, enter `.gitlab-ci.yml`.
1. In the large text box, paste this sample configuration:

   ```yaml
   stages:
     - build
     - test

   job_build:
     stage: build
     script:
       - echo "Building the project"

   job_test:
     stage: test
     script:
       - echo "Running tests"
   ```

   In this configuration there are two jobs that the runner runs: a build job and a test job.
1. Select **Commit changes**.

## Create and register a project runner

Next, create a project runner and register it. You must register the runner to link it
to GitLab so that it can pick up jobs from the project pipeline.

To create a project runner:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand the **Runners** section.
1. Select **New project runner**.
1. Select your operating system.
1. In the **Tags** section, select the **Run untagged** checkbox. [Tags](../../ci/runners/configure_runners.md#control-jobs-that-a-runner-can-run) specify which jobs
   the runner can run and are optional.
1. Select **Create runner**.
1. Follow the on-screen instructions to register the runner from the command line. When prompted:
   - For `executor`, because your runner will run directly on the host computer, enter `shell`. The [executor](https://docs.gitlab.com/runner/executors/)
     is the environment where the runner executes the job.
   - For `GitLab instance URL`, use the URL for your GitLab instance. For example, if your project
     is hosted on `gitlab.example.com/yourname/yourproject`, then your GitLab instance URL is `https://gitlab.example.com`.
     If your project is hosted on GitLab.com, the URL is `https://gitlab.com`.
1. Start your runner:

   ```shell
   gitlab-runner run
   ```

### Check the runner configuration file

After you register the runner, the configuration and runner authentication token is saved to your `config.toml`. The runner uses the
token to authenticate with GitLab when picking up jobs from the job queue.

You can use the `config.toml` to
define more [advanced runner configurations](https://docs.gitlab.com/runner/configuration/advanced-configuration.html).

Here's what your `config.toml` should look like after you register and start the runner:

```toml
  [[runners]]
  name = "my-project-runner1"
  url = "http://127.0.0.1:3000"
  id = 38
  token = "glrt-TOKEN"
  token_obtained_at = 2023-07-05T08:56:33Z
  token_expires_at = 0001-01-01T00:00:00Z
  executor = "shell"
```

## Trigger a pipeline to run your runner

Next, trigger a pipeline in your project so you can view your runner execute a job.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Build > Pipelines**.
1. Select **New pipeline**.
1. Select a job to view the job log. The output should look similar to this example, which shows
   your runner successfully executing the job:

   ```shell
      Running with gitlab-runner 16.2.0 (782e15da)
      on my-project-runner TOKEN, system ID: SYSTEM ID
      Preparing the "shell" executor
      00:00
      Using Shell (bash) executor...
      Preparing environment
      00:00
      /Users/username/.bash_profile: line 9: setopt: command not found
      Running on MACHINE-NAME...
      Getting source from Git repository
      00:01
      /Users/username/.bash_profile: line 9: setopt: command not found
      Fetching changes with git depth set to 20...
      Reinitialized existing Git repository in /Users/username/project-repository
      Checking out 7226fc70 as detached HEAD (ref is main)...
      Skipping object checkout, Git LFS is not installed for this repository.
      Consider installing it with 'git lfs install'.
      Skipping Git submodules setup
      Executing "step_script" stage of the job script
      00:00
      /Users/username/.bash_profile: line 9: setopt: command not found
      $ echo "Building the project"
      Building the project
      Job succeeded

   ```

You have now successfully created, registered, and run your first runner!
