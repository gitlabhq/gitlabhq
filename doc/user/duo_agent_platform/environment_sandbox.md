---
stage: AI-powered
group: Agent Foundations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
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

The execution environment sandbox is automatically applied when using a compatible Docker image with Anthropic Sandbox Runtime (SRT) installed. This includes using the default GitLab Docker image
(release [v0.0.6](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/-/tags/v0.0.6) and later) or a [custom image with SRT installed](#install-anthropic-sandbox-runtime-srt-on-a-custom-image).

The sandbox is enabled when:

- Anthropic Sandbox Runtime (SRT) is available in the Docker image.
- GitLab Duo Agent Platform sessions are being executed on a runner (local environments are not being sandboxed).

For information about CI/CD variable differences between default and custom
image configurations, see
[Flow execution variables](flows/execution_variables.md).

## Prerequisites

To use the execution environment sandbox, you need:

- GitLab Duo Agent Platform enabled in your project.
- Privileged runner mode enabled. It is [required for sandboxing to function](flows/execution.md#configure-runners).
- A compatible Docker image: this could be the [default GitLab Docker](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/container_registry) image on version `v0.0.6` or above, or a [custom image with Anthropic Sandbox Runtime (SRT) installed](#install-anthropic-sandbox-runtime-srt-on-a-custom-image).

## How it works

The execution environment sandbox uses [Anthropic Sandbox Runtime (SRT)](https://github.com/anthropic-experimental/sandbox-runtime) to wrap flow execution with the following protections:

- Network isolation: Intercepts all network requests before they leave
  the execution environment and validates them against allowlisted domains.
- Filesystem restrictions: Limits read and write access to specific directories
  and blocks access to sensitive files.
- Graceful fallback: If SRT is unavailable or required operating system privileges
  are missing, the flow runs directly with a warning message.

## Install Anthropic Sandbox Runtime (SRT) on a custom image

If you use a custom image, for example, with an [`agent-config.yml`](flows/execution.md#create-the-configuration-file),
Anthropic SRT version `0.0.20` or later must be installed and available in the environment.

SRT is available through `npm` as `@anthropic-ai/sandbox-runtime`. The following example shows the installation stage
in a Dockerfile:

```dockerfile
# Install srt sandboxing with cache clearing and verification
ARG SANDBOX_RUNTIME_VERSION=0.0.20
RUN npm cache clean --force && \
    npm install -g @anthropic-ai/sandbox-runtime@${SANDBOX_RUNTIME_VERSION} && \
    test -s "$(npm root -g)/@anthropic-ai/sandbox-runtime/package.json" && \
    srt --version

```

At runtime, the runner checks that the SRT is available and working:

```shell
$ if which srt > /dev/null; then
$ echo "SRT found, creating config..."
SRT found, creating config...
$ echo '{"network":{"allowedDomains":["host.docker.internal","localhost","gitlab.com","*.gitlab.com","duo-workflow-svc.runway.gitlab.net"],"deniedDomains":[],"allowUnixSockets":["/var/run/docker.sock"],"allowLocalBinding":true},"filesystem":{"denyRead":["~/.ssh"],"allowWrite":["./","/tmp/"],"denyWrite":[],"allowGitConfig":true}}' > /tmp/srt-settings.json
$ echo "Testing SRT sandbox capabilities..."
Testing SRT sandbox capabilities...
```

The following error might occur during runtime, which may indicate that dependencies for SRT are
not available:

```shell
Warning: SRT found but can't create sandbox (insufficient privileges), running command directly
```

To resolve this:

1. Use bash to verify the image with the following command:

   ```shell
   docker run --rm -it <image>:<tag> /bin/bash
   ```

1. Use `srt`:

   ```shell
   srt ls
   ```

1. If the following error displays, you must install additional dependencies to your custom image:

   ```shell
   Error: Sandbox dependencies are not available on this system. Required: ripgrep (rg), bubblewrap (bwrap), and socat.
   ```

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
