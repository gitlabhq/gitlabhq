---
stage: Software Supply Chain Security
group: AI Governance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Record Claude Code, Cursor, and Codex sessions with the GitLab CLI so they appear on the AI Governance dashboard as Externally Connected Agents (ECAs).
title: Connect Externally Connected Agents (ECAs) to the AI Governance dashboard
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Limited availability

{{< /details >}}

{{< history >}}

- Session capture for coding agents [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/245529) in GitLab 19.3 [with a feature flag](../../administration/feature_flags/_index.md) named `ai_agent_session_tracking`. Disabled by default.
- Cursor and Codex sessions [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/260978) in GitLab 19.5.
- [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/261046) in GitLab 19.5.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

When coding agents such as Claude Code, Cursor, and Codex run on a developer's computer,
the AI Governance dashboard can show them as Externally Connected Agents (ECAs) through the GitLab CLI (`glab`).

The GitLab CLI (`glab`) reads each agent's local transcript and sends the session and its events
to the GitLab project the agent worked in. The sessions then appear:

- On the [AI Governance Dashboard](governance-dashboard.md).
- In the AI audit event report.

> [!warning]
> This feature is in [beta](../../policy/development_stages_support.md).
> It is subject to change without notice.
> For more information, see [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).

`glab` finds the project from the Git remote of the folder the agent ran in:

- For Claude Code, `glab` picks the remote the same way as its other commands.
  That is, `glab` uses the remote set with `glab repo set-default`, otherwise `upstream`, then `gitlab`, then `origin`.
  In a fork checkout, Claude Code sessions go to the upstream project.
- For Codex, `glab` uses the repository URL that Codex recorded, otherwise `origin`.
- For Cursor, `glab` uses `origin`.

The remote must point to a GitLab instance that `glab` is signed in to.
Sessions in folders without such a remote are not sent.

## Prerequisites

- GitLab Premium or Ultimate with GitLab Duo Agent Platform for the top-level group.
- [`glab`](../../editor_extensions/gitlab_cli/_index.md) 1.122.0 or later, signed in to your GitLab instance.
- At least the Developer role for the project.
- **Allow external agents** turned on for the top-level group. It is on by default.
  The setting belongs to the AI Catalog
  [external agents](../duo_agent_platform/agents/external.md#turn-external-agents-on-or-off)
  that run in CI/CD pipelines, and it also controls session capture.
  Turning it off stops the sessions of local coding agents too.
- [**Store AI audit events**](ai-audit-events.md#enable-ai-audit-event-storage) turned on
  for the group or project.
  Without it, only the session is recorded, not its events and tool calls.
  The setting is off by default. To change it, you need the Owner or Security Manager role.
- A computer running macOS or Linux.

## Set up session capture

Set up session capture once for each user account on each computer that runs an agent.
The commands in this section are documented in the
[`glab govern` reference](https://docs.gitlab.com/cli/govern/).

`glab govern setup` always installs the Claude Code hooks. `glab` also installs Claude Code hooks when
you pass the `--agents` options, where it asks for confirmation. If calling `glab` in a script, pass `--yes`.

### Capture Claude Code sessions

Claude Code sessions are captured through hooks, which send the session after each reply when `glab` can sign in from the hook.
The background job sends anything the hooks missed.

To capture Claude Code sessions, run:

```shell
glab govern setup
```

This command installs:

- A Stop hook and a SessionEnd hook in `~/.claude/settings.json`.
  The hooks send the session after every reply and mark it completed when the session ends.
- A background job that runs every 30 minutes.
  The job sends anything the hooks missed and marks sessions completed after 24 hours without activity.
  On macOS the job is a `launchd` agent, on Linux a `systemd` user timer.

Sessions that ended before you ran the command are not sent.

### Capture Cursor and Codex sessions

`glab` does not install hooks for Cursor and Codex.
The background job finds their sessions by scanning `~/.cursor/projects` and `~/.codex/sessions`
every 30 minutes.

To capture Cursor and Codex sessions, run:

```shell
glab govern setup --agents codex,cursor
```

The job also sends sessions from before you ran the command, if they were active in the last 89 days
and belong to a project on a GitLab instance that `glab` is signed in to.
A session is marked completed after 24 hours without activity.
Codex sessions stored in a custom `CODEX_HOME` folder are not found.

To change which agents are captured, run the command again with a different `--agents` list.
To stop capturing Cursor and Codex sessions, run it with `--agents ""`.

### Verify the setup

To check that session capture is configured correctly, run:

```shell
glab govern doctor
```

The command:

- Checks that `glab` is signed in to your default GitLab host and is in your `PATH`.
- Checks that the Claude Code hooks are in `~/.claude/settings.json` and that the GitLab API is reachable.
- Reports whether the background job is installed and how its last run went.
- For each failing check, describes how to fix it.

The last-run line lists:

- Projects where session capture is not enabled.
- Agent types that GitLab rejected.
- Cursor sessions that `glab` skipped.

The command reads only the global `~/.claude/settings.json`.
Hooks in a project's `.claude` folder are reported as missing, and the background job skips
Claude Code sessions while the global Stop hook is missing.

To send sessions now instead of waiting for the background job, run:

```shell
glab govern audit sync --all
```

## Data that is sent

For each session, `glab` sends:

- The prompts you type. Prompts over 8 KB are truncated. The first prompt also becomes the session's goal.
- Each tool call with its arguments, such as commands, file paths, and edits.
  Arguments over 8 KB are replaced with a marker.
- Each tool call's outcome, duration, and error message. Error messages are cut at 255 characters.
- The model and token usage of each response.
- When a session completes, a checksum of the transcript file.

Tool output and the text of responses are not sent, except the first 255 characters of a failed
tool call's output are sent as an error message.
To identify the computer, `glab` sends a hashed machine ID.

Different agents record different details:

| Agent | Difference to Claude Code |
|-------|---------------------------|
| Codex | Every tool call's outcome is recorded as completed, with no error message, because Codex does not record whether it succeeded. |
| Cursor | Only prompts and tool calls are sent, because Cursor records no results, token usage, or timestamps. Events are timed by the transcript's last modification. |

## View ECA sessions

Sessions from Externally Connected Agents (ECAs) appear on the AI Governance dashboard when the **Show** control
is set to **All agents** (the default) or **Connected**:

- The **Recent agent sessions** card names each session after its agent. For example, **Cursor (glab)**
  or **Claude Code (glab)**.
- The **Most used agents** card lists each connected agent with the number of machines and users
  that ran it. For example, **2 machines · 2 users**.
- The KPI tiles and the other cards count the sessions and tool calls alongside GitLab Duo Agent Platform
  sessions.

The sessions and their events are also listed in the AI audit event report:

- Claude Code sessions appear right after the first reply and are marked finished when you exit the agent.
  If the exit hook did not run, the background job marks the session finished after 24 hours without activity.
- Cursor and Codex sessions usually appear no later than 30 minutes after you use the agent,
  while the computer is on and you are signed in.
  On macOS, the first run of the background job is 30 minutes after setup.
  These sessions are marked finished after 24 hours without activity.
- Dashboard numbers update after a short delay.

## Stop capturing sessions

To remove the background job and stop capturing Cursor and Codex sessions, run:

```shell
glab govern setup --uninstall
```

The Claude Code hooks stay in place.
To stop capturing Claude Code sessions, remove the two `glab govern audit sync` entries from the `hooks`
section of `~/.claude/settings.json`.
Without the Stop hook, the background job also skips Claude Code sessions.

Sessions already sent to GitLab stay on the dashboard.

## Troubleshooting

| Problem | Cause | Resolution |
|---------|-------|------------|
| `glab govern doctor` reports a failed check. | The setup on this computer is incomplete. | Follow the fix that the check prints. |
| The last-run line of `glab govern doctor` says session capture is not enabled for a project. | Session capture is turned off for that project. | Contact GitLab Support. |
| `glab govern audit sync --all` prints a `403 Forbidden` warning, or `glab govern doctor` shows it as the last run's error. | Your role on the project is below Developer, the group does not have GitLab Duo Agent Platform, **Allow external agents** is turned off for the top-level group, or a group Owner revoked this computer's agent identity. For Claude Code in a fork checkout, the session went to the upstream project. | Check the role and the settings with a group Owner. In a fork checkout, run `glab repo set-default` and choose the project the sessions should go to. |
| A session appears, but has no events or tool calls. | **Store AI audit events** is turned off for the group or project. | Turn the setting on. You need the Owner or Security Manager role. Events from before the change are not recorded. |
| A session was sent, but is not on the dashboard. | The dashboard reads data that is processed in the background, or the filters exclude the session. | Set **Show** to **All agents** or **Connected**, check the date range, then wait a few minutes and reload the page. |
| A Cursor session is never sent. | `glab` could not confirm which folder the session ran in. This happens when the folder moved, when another folder's path differs only in punctuation (for example `code/cli-docs` and `code/cli/docs`), or when every file the session touched is outside the folder. It also happens when the folder has no `origin` remote. | Run `glab govern doctor` and read the "not synced" reason. Keep the folder where it was when the session ran, rename folders whose paths differ only in punctuation, and make sure the folder has an `origin` remote. |
| `glab govern doctor` says an agent type is not supported by GitLab yet. | GitLab did not accept that agent type when `glab` first found the session. Such sessions are never sent. | Sessions that `glab` finds after GitLab accepts the agent type are sent. If the message persists, contact GitLab Support. |

## Related topics

- [AI Governance Dashboard](governance-dashboard.md)
- [Audit AI events](ai-audit-events.md)
- [GitLab CLI](../../editor_extensions/gitlab_cli/_index.md)
