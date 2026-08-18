---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Options, commands, and environment variables for the GitLab Duo CLI.
title: GitLab Duo CLI reference
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use these options, commands, and environment variables when you start or run the GitLab Duo CLI.

This is not a complete list. For a full reference, see the
[GitLab Duo CLI complete reference](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md).

## Options

The GitLab Duo CLI supports these options:

- `-C, --cwd <path>`: Change the working directory.
- `-h, --help`: Display help for the GitLab Duo CLI or a specific command. For example, `duo --help` or
  `duo run --help`.
- `-v`, `--version`: Display version information.
- `--model <model>`: Select the AI model to use for the session.

For a complete list of options, see the GitLab Duo CLI complete reference.

## Commands

The following commands are available for each setup:

{{< tabs >}}

{{< tab title="glab" >}}

- `glab duo cli`: Start interactive mode.
- `glab duo cli log`: View and manage logs.
- `glab duo cli run`: Start headless mode.

{{< /tab >}}

{{< tab title="duo" >}}

- `duo`: Start interactive mode.
- `duo config`: Manage the configuration and authentication settings.
- `duo log`: View and manage logs.
- `duo run`: Start headless mode.

{{< /tab >}}

{{< /tabs >}}

For a complete list of commands, see the GitLab Duo CLI complete reference.

## Environment variables

{{< history >}}

- `AI_AGENT` environment variable [introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.95.0) in GitLab Duo CLI 8.95.0, during the GitLab 19.0 release.

{{< /history >}}

You can configure the GitLab Duo CLI using environment variables:

- `DUO_WORKFLOW_GIT_HTTP_PASSWORD`: Git HTTP authentication password.
- `DUO_WORKFLOW_GIT_HTTP_USER`: Git HTTP authentication username.
- `GITLAB_BASE_URL` or `GITLAB_URL`: GitLab instance URL.
- `GITLAB_DUO_MODEL`: AI model to use for the session.
- `GITLAB_OAUTH_TOKEN` or `GITLAB_TOKEN`: Authentication token.

When the GitLab Duo CLI runs a command on your behalf, it sets the `AI_AGENT` environment variable
in that process. Scripts and tools can read `AI_AGENT` to detect that they are running in an
AI-driven execution.

For a complete list of environment variables, see the GitLab Duo CLI complete reference.

## Terminal progress signals

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/releases/v8.79.0) in GitLab Duo CLI 8.79.0, during the GitLab 18.11 release.

{{< /history >}}

In both interactive and headless modes, the GitLab Duo CLI reports its status
by writing Operating System Command (OSC) `9;4` progress escape sequences to
`/dev/tty`. Terminals that support this sequence display a progress indicator
on the tab or window that runs the GitLab Duo CLI. Terminal multiplexers and
status tools can parse the same sequences to detect the GitLab Duo CLI state.

The GitLab Duo CLI writes each signal as `ESC ] <sequence> ESC \` where `<sequence>` is one of:

| Sequence   | State         | Description                                       |
|------------|---------------|---------------------------------------------------|
| `9;4;3`    | Indeterminate | The GitLab Duo CLI is processing a request.       |
| `9;4;4;50` | Paused        | A tool call is waiting for your approval.         |
| `9;4;0`    | Clear         | The GitLab Duo CLI is idle and waiting for input. |
| `9;4;2`    | Error         | The last request ended with an error.             |

The GitLab Duo CLI writes these signals only when its standard output is
attached to a terminal and the `/dev/tty` device is available. Because the
signals go to `/dev/tty` instead of standard output, they do not appear in
redirected or captured output. When the GitLab Duo CLI exits, it clears the
progress state.

When the GitLab Duo CLI runs in a `tmux` session, it wraps the sequences in the
`tmux` passthrough escape sequence. In `tmux` 3.3 and later, the sequences
reach the outer terminal only if you turn on the `allow-passthrough` option.

The GitLab Duo CLI can also send
[system notifications](use.md#system-notifications) when a session needs your
attention.
