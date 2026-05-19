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
- `network_policy` setting [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/590021) in GitLab 18.10.
- `allow_all_unix_sockets` network policy setting [introduced](https://gitlab.com/gitlab-org/gitlab/-/work_items/590871) in GitLab 18.11.
- Instance-level and group-level network access controls [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/229531) in GitLab 18.11 [with feature flags](../../administration/feature_flags/_index.md) named `dap_instance_network_access_controls` and `dap_group_network_access_controls`. Disabled by default.

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
$ echo '{"network":{"allowedDomains":["host.docker.internal","localhost","gitlab.com","*.gitlab.com","duo-workflow-svc.runway.gitlab.net"],"deniedDomains":[],"allowAllUnixSockets":false},"filesystem":{"denyRead":["~/.ssh"],"allowWrite":["./","/tmp"],"denyWrite":["/opt/.gitlab-sandbox"],"allowGitConfig":true}}' > /opt/.gitlab-sandbox/srt-settings.json
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

### Configure sandbox settings

Use an [`agent-config.yml`](flows/execution.md#create-the-configuration-file) file to configure some of your sandbox settings.

By default, the sandbox permits access to the following configurations:

- Default allow-listed domains. These are configured automatically and cannot be changed or updated.

### Environment variables

Only the environment variables and parameters required to run DAP and Git operations are accessible from the sandbox environment.

### Filesystem configuration

The sandbox enforces the following filesystem restrictions:

- Read restrictions: SSH keys (`~/.ssh`) are blocked.
- Write allowed: Current directory (`./`) and `/tmp`.
- Write restricted: `/opt/.gitlab-sandbox` (used for platform-internal files like sandbox settings).
- Git configuration access: Allowed.

### Configure a network policy

SRT is included in the default GitLab-provided Docker image. You can also
[install SRT on a custom image](#install-anthropic-sandbox-runtime-srt-on-a-custom-image).

When SRT is installed, flows can access only the following domains by default.
These domains are always allowed and cannot be removed:

- `localhost`
- `host.docker.internal`
- Your GitLab instance domain (for example, `gitlab.com`, `*.gitlab.com`)
- The GitLab Duo Workflow Service domain

If you use a custom image without SRT,
no network restrictions are applied and the flow can access any domain
reachable from the runner.

> [!note]
> The `network_policy` does not allow `"*"` in the `allowed_domains` or the `denied_domains`. SRT does not
> support turning on all network traffic. However, wildcards are allowed as part of domains,
> for example `"*.domain.com"`.

#### Administrator network policy controls

When a top-level group owner on GitLab.com or instance administrator on GitLab
Self-Managed configures network access controls, those settings define the
baseline policy for all flows. The **Allow projects to extend network sandbox
settings** checkbox determines which settings are applied when project owners
configure them in `agent-config.yml`.

**Flexible mode** (**Allow projects to extend network sandbox settings** enabled):

- `allowed_domains` from `agent-config.yml` are merged with the admin allow-list.
- `denied_domains` from `agent-config.yml` are merged with the admin deny-list.
- `include_recommended_allowed` in `agent-config.yml` overrides the admin setting.
- `allow_all_unix_sockets` in `agent-config.yml` overrides the admin setting.

**Strict mode** (**Allow projects to extend network sandbox settings** disabled):

- `denied_domains` from `agent-config.yml` are merged with the admin deny-list.
- `include_recommended_allowed` can only be set to `false` to tighten a setting the admin enabled.
  It has no effect when the admin has it disabled.
- `allow_all_unix_sockets` can only be set to `false` to tighten a setting the admin enabled.
  It has no effect when the admin has it disabled.
- `allowed_domains` from `agent-config.yml` are ignored.

#### Configure project-level settings

To allow or deny additional domains, add a `network_policy` to your `agent-config.yml` file:

```yaml
network_policy:
  include_recommended_allowed: true # default: false
  allow_all_unix_sockets: true      # default: false
  allowed_domains:
    - my-own-site.com
  denied_domains:
    - malicious.com
```

#### Allow Unix socket access

Use the `allow_all_unix_sockets` setting to grant the flow access to all Unix domain sockets on
the host. This is disabled by default.

> [!warning]
> Enabling `allow_all_unix_sockets` grants access to all Unix sockets. Enable this only when necessary and only in trusted environments.

### Configure network access controls for your instance or group

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/229531) in GitLab 18.11 [with feature flags](../../administration/feature_flags/_index.md) named `dap_instance_network_access_controls` and `dap_group_network_access_controls`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.
> This feature is available for testing, but not ready for production use.

In addition to [project-level `agent-config.yml` settings](#configure-a-network-policy),
administrators and top-level group owners can manage network access controls through the GitLab UI.
These settings are stored at the instance level (GitLab Self-Managed) or top-level group level
(GitLab.com) and are inherited by all projects underneath.

For a description of how these settings combine with project-level `agent-config.yml`,
see [Administrator network policy controls](#administrator-network-policy-controls).

#### Configure instance-level network access controls

Prerequisites:

- You must be an administrator.

To configure instance-level network access controls:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Data and privacy**, in the **Network access** section, configure the
   following settings:
   - **Include recommended domains in the allowlist**: When enabled, a curated
     list of commonly needed domains is automatically included in the allowlist.
   - **Allow all Unix sockets**: When enabled, all Unix socket connections are
     permitted for agent platform operations.
   - **Allow projects to extend network sandbox settings**: When enabled, project
     maintainers can add additional domains to the allowlist, allow all Unix
     sockets, and include recommended domains through their `agent-config.yml`
     file.
1. Optional. Use the **Allowed domains** card to add or remove specific domains
   from the allowlist.
1. Optional. Use the **Blocked domains** card to add or remove specific domains
   from the denylist.
1. Select **Save changes**.

#### Configure top-level group network access controls (GitLab.com)

Prerequisites:

- You must have the Owner role for the top-level group.
- The group must be a top-level group on GitLab.com. Subgroups inherit the
  settings from their top-level group.

To configure group-level network access controls:

1. On the top bar, select **Search or go to** and find your top-level group.
1. In the left sidebar, select **Settings**, then **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Data and privacy**, in the **Network access** section, configure the
   same settings as described in
   [Configure instance-level network access controls](#configure-instance-level-network-access-controls).
1. Select **Save changes**.

#### Related API resources

- Instance-level booleans:
  [`duoSettingsUpdate`](../../api/graphql/reference/_index.md#mutationduosettingsupdate)
  GraphQL mutation.
- Group-level booleans:
  [Update group attributes](../../api/groups.md#update-group-attributes) REST API, using the
  `ai_settings_attributes` parameter.
- Domain allowlist and denylist:
  [`aiDomainSettingsInstanceUpdate`](../../api/graphql/reference/_index.md#mutationaidomainsettingsinstanceupdate)
  and
  [`aiDomainSettingsNamespaceUpdate`](../../api/graphql/reference/_index.md#mutationaidomainsettingsnamespaceupdate)
  GraphQL mutations.

### Turn on allowed domains

To give your flows access to a set of external domains used for package registries and development tools,
turn on the `include_recommended_allowed` setting.

This setting is disabled by default (`false`). To turn it on, in your `agent-config.yml` file,
set `include_recommended_allowed` to `true`.

When network access controls are enabled in strict mode (**Allow projects to extend network sandbox settings** disabled),
you can only disable `include_recommended_allowed`. Setting it to `true` has no effect when the
admin has it disabled.

> [!warning]
> Enabling `include_recommended_allowed` permits network access to a broad set of external domains.
> These egress endpoints could potentially be used to exfiltrate data from your environment.
> Enable this only when necessary and only in trusted environments.

This setting turns on access to the following domains:

- `github.com`
- `www.github.com`
- `api.github.com`
- `npm.pkg.github.com`
- `raw.githubusercontent.com`
- `pkg-npm.githubusercontent.com`
- `objects.githubusercontent.com`
- `codeload.github.com`
- `avatars.githubusercontent.com`
- `camo.githubusercontent.com`
- `gist.github.com`
- `gitlab.com`
- `www.gitlab.com`
- `registry.gitlab.com`
- `bitbucket.org`
- `www.bitbucket.org`
- `api.bitbucket.org`
- `registry-1.docker.io`
- `auth.docker.io`
- `index.docker.io`
- `hub.docker.com`
- `www.docker.com`
- `production.cloudflare.docker.com`
- `download.docker.com`
- `gcr.io`
- `*.gcr.io`
- `ghcr.io`
- `mcr.microsoft.com`
- `*.data.mcr.microsoft.com`
- `public.ecr.aws`
- `cloud.google.com`
- `accounts.google.com`
- `gcloud.google.com`
- `storage.googleapis.com`
- `compute.googleapis.com`
- `container.googleapis.com`
- `artifactregistry.googleapis.com`
- `cloudresourcemanager.googleapis.com`
- `oauth2.googleapis.com`
- `www.googleapis.com`
- `login.microsoftonline.com`
- `packages.microsoft.com`
- `dotnet.microsoft.com`
- `dot.net`
- `dev.azure.com`
- `s3.amazonaws.com`
- `*.s3.amazonaws.com`
- `*.codeartifact.amazonaws.com`
- `*.s3.api.aws`
- `*.codeartifact.api.aws`
- `download.oracle.com`
- `yum.oracle.com`
- `registry.npmjs.org`
- `www.npmjs.com`
- `www.npmjs.org`
- `npmjs.com`
- `npmjs.org`
- `yarnpkg.com`
- `registry.yarnpkg.com`
- `pypi.org`
- `www.pypi.org`
- `files.pythonhosted.org`
- `pythonhosted.org`
- `test.pypi.org`
- `pypi.python.org`
- `pypa.io`
- `www.pypa.io`
- `rubygems.org`
- `www.rubygems.org`
- `api.rubygems.org`
- `index.rubygems.org`
- `ruby-lang.org`
- `www.ruby-lang.org`
- `rubyonrails.org`
- `www.rubyonrails.org`
- `rvm.io`
- `get.rvm.io`
- `crates.io`
- `www.crates.io`
- `index.crates.io`
- `static.crates.io`
- `rustup.rs`
- `static.rust-lang.org`
- `www.rust-lang.org`
- `proxy.golang.org`
- `sum.golang.org`
- `index.golang.org`
- `golang.org`
- `www.golang.org`
- `goproxy.io`
- `pkg.go.dev`
- `maven.org`
- `repo.maven.org`
- `central.maven.org`
- `repo1.maven.org`
- `jcenter.bintray.com`
- `gradle.org`
- `www.gradle.org`
- `services.gradle.org`
- `plugins.gradle.org`
- `kotlin.org`
- `www.kotlin.org`
- `spring.io`
- `repo.spring.io`
- `packagist.org`
- `www.packagist.org`
- `repo.packagist.org`
- `nuget.org`
- `www.nuget.org`
- `api.nuget.org`
- `pub.dev`
- `api.pub.dev`
- `hex.pm`
- `www.hex.pm`
- `cpan.org`
- `www.cpan.org`
- `metacpan.org`
- `www.metacpan.org`
- `api.metacpan.org`
- `cocoapods.org`
- `www.cocoapods.org`
- `cdn.cocoapods.org`
- `haskell.org`
- `www.haskell.org`
- `hackage.haskell.org`
- `swift.org`
- `www.swift.org`
- `archive.ubuntu.com`
- `security.ubuntu.com`
- `ubuntu.com`
- `www.ubuntu.com`
- `*.ubuntu.com`
- `ppa.launchpad.net`
- `launchpad.net`
- `www.launchpad.net`
- `dl.k8s.io`
- `pkgs.k8s.io`
- `k8s.io`
- `www.k8s.io`
- `releases.hashicorp.com`
- `apt.releases.hashicorp.com`
- `rpm.releases.hashicorp.com`
- `archive.releases.hashicorp.com`
- `hashicorp.com`
- `www.hashicorp.com`
- `repo.anaconda.com`
- `conda.anaconda.org`
- `anaconda.org`
- `www.anaconda.com`
- `anaconda.com`
- `continuum.io`
- `apache.org`
- `www.apache.org`
- `archive.apache.org`
- `downloads.apache.org`
- `eclipse.org`
- `www.eclipse.org`
- `download.eclipse.org`
- `nodejs.org`
- `www.nodejs.org`
- `sourceforge.net`
- `*.sourceforge.net`
- `packagecloud.io`
- `*.packagecloud.io`
- `json-schema.org`
- `www.json-schema.org`
- `json.schemastore.org`
- `www.schemastore.org`
- `*.modelcontextprotocol.io`

## Warnings and fallback behavior

If sandboxing is unavailable or cannot be applied:

- The flow runs directly without sandbox protection
- A warning message is displayed within CI job logs with a link to runner configuration guidance

This ensures flows continue to execute even if sandboxing cannot be enabled, while alerting you to the situation.
