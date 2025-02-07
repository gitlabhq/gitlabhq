---
stage: Verify
group: Runner
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Interactive web terminals
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Interactive web terminals give the user access to a terminal in GitLab for
running one-off commands for their CI pipeline. You can think of it like a method for
debugging with SSH, but done directly from the job page. Since this is giving the user
shell access to the environment where [GitLab Runner](https://docs.gitlab.com/runner/)
is deployed, some [security precautions](../../administration/integration/terminal.md#security) were
taken to protect the users.

NOTE:
[Instance runners on GitLab.com](../runners/_index.md) do not
provide an interactive web terminal. Follow
[this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/24674) for progress on
adding support. For groups and projects hosted on GitLab.com, interactive web
terminals are available when using your own group or project runner.

## Configuration

Two things need to be configured for the interactive web terminal to work:

- The runner needs to have
  [`[session_server]` configured properly](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-session_server-section)
- If you are using a reverse proxy with your GitLab instance, web terminals need to be
  [enabled](../../administration/integration/terminal.md#enabling-and-disabling-terminal-support)

### Partial support for Helm chart

Interactive web terminals are partially supported in `gitlab-runner` Helm chart.
They are enabled when:

- The number of replica is one
- You use the `loadBalancer` service

Support for fixing these limitations is tracked in the following issues:

- [Support of more than one replica](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/issues/323)
- [Support of more service types](https://gitlab.com/gitlab-org/charts/gitlab-runner/-/issues/324)

## Debugging a running job

NOTE:
Not all executors are
[supported](https://docs.gitlab.com/runner/executors/#compatibility-chart).

NOTE:
The `docker` executor does not keep running
after the build script is finished. At that point, the terminal automatically
disconnects and does not wait for the user to finish. Follow
[this issue](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/3605) for updates on
improving this behavior.

Sometimes, when a job is running, things don't go as you would expect, and it
would be helpful if one can have a shell to aid debugging. When a job is
running, on the right panel, you can see a `debug` button (**{external-link}**) that opens the terminal
for the current job. Only the person who started a job can debug it.

![Example of job running with terminal available](img/interactive_web_terminal_running_job_v17_3.png)

When selected, a new tab opens to the terminal page where you can access
the terminal and type commands like in a standard shell.

![terminal of the job](img/interactive_web_terminal_page_v11_1.png)

If you have the terminal open and the job has finished with its tasks, the
terminal blocks the job from finishing for the duration configured in
[`[session_server].session_timeout`](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-session_server-section) until you
close the terminal window.

![finished job with terminal open](img/finished_job_with_terminal_open_v11_2.png)
