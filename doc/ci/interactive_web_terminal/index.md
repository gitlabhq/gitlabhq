# Getting started with interactive web terminals

> Introduced in GitLab 11.3.

CAUTION: **Warning:**
Interactive web terminals are in beta, so they might not work properly and
lack features. For more information [follow issue #25990](https://gitlab.com/gitlab-org/gitlab-ce/issues/25990).

Interactive web terminals give the user access to a terminal in GitLab for
running one-of commands for their CI pipeline.

NOTE: **Note:**
This is not available for the shared Runners on GitLab.com.
To make use of this feature, you need to provide your
[own Runner](https://docs.gitlab.com/runner/install/) and properly
[configure it](#configuration).

## Configuration

Two things need to be configured for the interactive web terminal to work:

- The Runner needs to have [`[session_server]` configured
  properly][session-server]
- Web terminals need to be
  [enabled](../../administration/integration/terminal.md#enabling-and-disabling-terminal-support)

## Debugging a running job

NOTE: **Note:** Not all executors are
[supported](https://docs.gitlab.com/runner/executors/#compatibility-chart).

Sometimes, when a job is running, things don't go as you would expect, and it
would be helpful if one can have a shell to aid debugging. When a job is
running, on the right panel you can see a button `debug` that will open the terminal
for the current job.

![Example of job running with terminal
available](img/interactive_web_terminal_running_job.png)

When clicked, a new tab will open to the terminal page where you can access
the terminal and type commands like a normal shell.

![terminal of the job](img/interactive_web_terminal_page.png)

If you have the terminal open and the job has finished with its tasks, the
terminal will block the job from finishing for the duration configured in
[`[session_server].terminal_max_retention_time`][session-server] until you
close the terminal window.

![finished job with terminal open](img/finished_job_with_terminal_open.png)

[session-server]: https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-session_server-section
