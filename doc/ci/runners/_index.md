---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Runners
---

Runners are the agents that run the [GitLab Runner](https://docs.gitlab.com/runner/) application, to execute GitLab CI/CD jobs in a pipeline.
They are responsible for running your builds, tests, deployments, and other CI/CD tasks defined in `.gitlab-ci.yml` files.

## Runner execution flow

The following is a basic workflow of how runners work:

1. A runner must first be [registered](https://docs.gitlab.com/runner/register/) with GitLab,
   which establishes a persistent connection between the runner and GitLab.
1. When a pipeline is triggered, GitLab makes the jobs available to the registered runners.
1. Matching runners pick up jobs, one job per runner, and execute them.
1. Results are reported back to GitLab in real-time.

For more information, see [Runner execution flow](https://docs.gitlab.com/runner/#runner-execution-flow).

## Runner job scheduling and execution

When a CI/CD job needs to be executed, GitLab creates a job based on the tasks defined in the `.gitlab-ci.yml` file.
The jobs are placed in a queue. GitLab checks for available runners that match:

- Runner tags
- Runner types (like shared or group)
- Runner status and capacity
- Required capabilities

The assigned runner receives the job details. The runner prepares the environment and runs the job's commands as specified in the `.gitlab-ci.yml` file.

## Runner categories

When deciding on which runners you want to execute your CI/CD jobs, you can choose:

- [GitLab-hosted runners](hosted_runners/_index.md) for GitLab.com or GitLab Dedicated users.
- [Self-managed runners](https://docs.gitlab.com/runner/) for all GitLab installations.

Runners can be group, project, or instance runners. GitLab-hosted runners are instance runners.

### GitLab-hosted runners

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Dedicated

GitLab-hosted runners are:

- Fully managed by GitLab.
- Available immediately without setup.
- Run on fresh VMs for each job.
- Include Linux, Windows, and macOS options.
- Automatically scaled based on demand.

Choose GitLab-hosted runners when:

- You want zero-maintenance CI/CD.
- You need quick setup without infrastructure management.
- Your jobs require isolation between runs.
- You're working with standard build environments.
- You're using GitLab.com or GitLab Dedicated.

### Self-managed runners

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Self-managed runners are:

- Installed and managed by you.
- Run on your own infrastructure.
- Customizable to your needs.
- Support various executors (including Shell, Docker, and Kubernetes).
- Can be shared or set to specific projects or groups.

Choose self-managed runners when:

- You need custom configurations.
- You want to run jobs in your private network.
- You require specific security controls.
- You require project or group runners.
- You need to optimize for speed with runner reuse.
- You want to manage your own infrastructure.

## Related topics

- [Install GitLab Runner](https://docs.gitlab.com/runner/install/)
- [Configure GitLab Runner](https://docs.gitlab.com/runner/configuration/)
- [Administer GitLab Runner](https://docs.gitlab.com/runner/)
- [Hosted runners for GitLab Dedicated](../../administration/dedicated/hosted_runners.md)
