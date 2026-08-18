---
stage: AI Clients
group: Developer Clients
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Command-line interface tool that brings the GitLab Duo Agent Platform to your terminal.
title: GitLab Duo CLI (`duo`)
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Model information" >}}

- [Default LLM](../duo_agent_platform/model_selection.md#default-models)
- Available on [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- Introduced as [experiment](../../policy/development_stages_support.md#experiment) in GitLab 18.9.
- [Added](https://gitlab.com/gitlab-org/cli/-/merge_requests/2838) to the GitLab CLI as an experiment in `glab` 1.87.0, during the GitLab 18.9 release.
- [Changed](https://gitlab.com/groups/gitlab-org/-/work_items/19716) from experiment to beta in GitLab 18.11.
- [Generally available](https://gitlab.com/groups/gitlab-org/-/work_items/19717) as GitLab Duo CLI 9.0.0 in GitLab 19.2.

{{< /history >}}

The GitLab Duo CLI is a command-line interface tool that brings [GitLab Duo Agentic Chat](../gitlab_duo_chat/agentic_chat.md)
to your terminal. Available for use with any operating system and editor, use the CLI to ask complex
questions about your codebase and to autonomously perform actions on your behalf.

The GitLab Duo CLI can help you:

- Understand your codebase structure, cross-file functionality, and individual code snippets.
- Build, modify, refactor, and modernize code.
- Troubleshoot errors and fix code issues.
- Automate CI/CD configuration, troubleshoot pipeline errors, and optimize pipelines.
- Perform multi-step development tasks autonomously.

> [!note]
> The GitLab Duo CLI is now generally available. Update to
> GitLab Duo CLI 9.0.0 or later for the full generally available experience.

You can use the GitLab Duo CLI through the [GitLab CLI](https://docs.gitlab.com/cli/) (`glab`),
or install and use the GitLab Duo CLI (`duo`) as a standalone AI tool.

The GitLab Duo CLI offers two modes:

- Interactive mode: Provides a chat experience similar to GitLab Duo Chat in the GitLab UI or in
  editor extensions. Supports build and plan modes.
- Headless mode: Enables non-interactive use in runners, scripts, and other automated workflows.

It also supports [custom instructions](../duo_agent_platform/customize/_index.md) set for
the GitLab Duo Agent Platform, including `chat-rules.md`, `AGENTS.md`, and `SKILL.md` files.

## Get started

1. [Set up](set_up.md) the GitLab Duo CLI.
1. [Use](use.md) the GitLab Duo CLI, either in interactive or headless mode.
1. [Customize](customize.md) the GitLab Duo CLI to better fit your workflow or use case.
1. Review the [reference documentation](reference.md) to learn more about how you can use the GitLab Duo CLI.

## Manage GitLab Duo CLI access

{{< details >}}

- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/242250) in GitLab 19.2.

{{< /history >}}

By default, GitLab Duo CLI access is turned on.

On GitLab Self-Managed and GitLab Dedicated, you can turn GitLab Duo CLI access on or off for an instance.

Prerequisites:

- You must be an administrator.

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **GitLab Duo**.
1. Select **Change configuration**.
1. Under **GitLab Duo CLI**, select or clear the **Turn on GitLab Duo CLI access** checkbox.
1. Select **Save changes**.

## Update the GitLab Duo CLI

To manually update the GitLab Duo CLI to the latest version, run the command for your setup:

{{< tabs >}}

{{< tab title="glab" >}}

```shell
glab duo cli --update
```

{{< /tab >}}

{{< tab title="duo" >}}

```shell
npm install --global @gitlab/duo-cli@latest
```

{{< /tab >}}

{{< /tabs >}}

## Contribute to the GitLab Duo CLI

For information on contributing to the GitLab Duo CLI, see the
[development guide](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/development.md).

## Related topics

- [GitLab Duo CLI complete reference](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/blob/main/packages/cli/docs/cli-reference.md)
- [Security considerations for editor extensions](../../editor_extensions/security_considerations.md)
- [GitLab CLI](https://docs.gitlab.com/cli/)
- [Customize GitLab Duo Agent Platform](../duo_agent_platform/customize/_index.md)
