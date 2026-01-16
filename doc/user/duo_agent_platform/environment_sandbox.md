---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see
  https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Remote execution environment sandbox
---

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/578048) in GitLab 18.7 [with a flags](../../administration/feature_flags/_index.md) named `ai_duo_agent_platform_network_firewall` and `ai_dap_executor_connects_over_ws`
- Feature flag `ai_duo_agent_platform_network_firewall` [enabled](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215950) in GitLab 18.7.
- Feature flag `ai_dap_executor_connects_over_ws` [enabled](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215774) in GitLab 18.7.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) in GitLab 18.8.

{{< /history >}}

The execution environment sandbox provides application-level network and filesystem isolation
that helps protect GitLab Duo Agent Platform remote flows from unauthorized network access
and data exfiltration. It is designed to help prevent data exfiltration attempts,
loading of malicious code from external sources, and unauthorized data gathering
while maintaining necessary connectivity for legitimate flow operations.

## When the sandbox is applied

The execution environment sandbox is automatically applied only when
using the default GitLab Docker image
(release [v0.0.6](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/-/tags/v0.0.6) and later)
for the GitLab Duo Agent Platform.

The sandbox is enabled when:

- No custom Docker image is specified in `agent-config.yml` file.
- GitLab Duo Agent Platform sessions are being executed on a runner (local environments are not being sandboxed).

If you specify a [custom Docker image](flows/execution.md#change-the-default-docker-image),
the sandbox is not applied, and your flow can access any domain reachable from your runner.

## Prerequisites

To use the execution environment sandbox, you need:

- GitLab Duo Agent Platform enabled in your project.
- Privileged runner mode enabled. It is [required for sandboxing to function](flows/execution.md#configure-runners).
- [Default GitLab Docker](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/container_registry) image on version `v0.0.6` or above, (sandbox does not apply to custom images).

## How it works

The execution environment sandbox uses [Anthropic Sandbox Runtime (SRT)](https://github.com/anthropic-experimental/sandbox-runtime) to wrap flow execution with the following protections:

- Network isolation: Intercepts all network requests before they leave
  the execution environment and validates them against allowlisted domains.
- Filesystem restrictions: Limits read and write access to specific directories
  and blocks access to sensitive files.
- Graceful fallback: If SRT is unavailable or required operating system privileges
  are missing, the flow runs directly with a warning message.

## Network and filesystem restrictions

When the execution environment sandbox is applied, the following restrictions are enforced.

### Network configuration

The sandbox allows network access to:

- [Allowlisted domains](#allowlisted-domains) (auto-configured).
- Unix socket access (Docker socket).
- Local binding.

### Filesystem configuration

The sandbox enforces the following filesystem restrictions:

- Read restrictions: SSH keys (`~/.ssh`) are blocked.
- Write allowed: Current directory (`./`) and temporary directory (`/tmp/`).
- Git configuration access: Allowed.

## Allowlisted domains

Only following domains are automatically allowlisted for network access:

- `host.docker.internal`
- `localhost`
- Your GitLab instance domain
- Your GitLab instance wildcard domain (for example, `*.gitlab.example.com`)

To track progress on allowlist customization, see [this epic](https://gitlab.com/groups/gitlab-org/-/epics/20247).

## Warnings and fallback behavior

If sandboxing is unavailable or cannot be applied:

- The flow runs directly without sandbox protection
- A warning message is displayed within CI job logs with a link to runner configuration guidance

This ensures flows continue to execute even if sandboxing cannot be enabled, while alerting you to the situation.
