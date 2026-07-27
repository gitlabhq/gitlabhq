---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Configure the CI/CD environment, setup scripts, caching, ID tokens, and runners that execute GitLab Duo Agent Platform flows.
title: Configure flow execution
---

{{< details >}}

- Tier: [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/477166) in GitLab 18.3.

{{< /history >}}

Flows use agents to execute tasks.

- Flows executed from the GitLab UI use CI/CD.
- Flows executed in an IDE run locally.

You can configure the environment where flows use CI/CD to execute.
You can also [use your own runners](#configure-runners-to-execute-flows), and
[specify variables in your jobs](execution-variables.md).

## Executor architecture

When a flow runs in CI/CD, the runner:

1. Downloads the `@gitlab/duo-cli` package from the `npm` registry.
1. Runs the GitLab Duo CLI, which uses WebSocket to connect to the GitLab Duo Workflow Service.
1. Executes tools (file operations, Git commands) as directed by the AI model.

The executor version is managed by GitLab and updated as part of regular releases.

## Configure CI/CD execution

To customize how flows are executed in CI/CD, create an agent configuration file in your project.

For a list of supported keys and their types, see the [`agent-config.yml` reference](agent-config-yaml.md).

> [!note]
> You cannot use predefined CI/CD variables to configure the `agent-config.yml`.
> You must use [variables](execution-variables.md#available-variables) for jobs that execute your flows.

### Create the agent configuration file

1. In your project's repository, create a `.gitlab/duo/` folder.
1. In the folder, create a configuration file named `agent-config.yml`.
1. Add your required configuration options.
1. Commit and push the file to your default branch.

The configuration is applied when flows run in CI/CD for your project.

For an example of a complete `agent-config.yml` file, see the [`agent-config.yml` reference](agent-config-yaml.md#complete-example).

> [!note]
> The configuration file is read-only from the project's default branch.
> Files committed to other branches are ignored, even when a flow runs from those branches.

### Configure setup scripts

You can define setup scripts that run before your flow executes. This is useful for installing dependencies, configuring environments, or initialization.

To add setup scripts, in the `agent-config.yml` file, add the following commands:

```yaml
setup_script:
  - apt-get update && apt-get install -y curl
  - pip install -r requirements.txt
  - echo "Setup complete"
```

These commands complete the following actions:

- Run before the main workflow commands.
- Execute in the order specified.
- Can be a single command or an array of commands.

The user context for `setup_script` depends on the Docker image. The default
GitLab image runs as `root`. Custom images run as the user defined in the
image's `USER` directive. If your `setup_script` requires root access (for
example, to install system packages), ensure your custom image is configured
accordingly.

> [!warning]
> `setup_script` commands run before SRT is applied and execute outside it.
> These commands have access to all environment variables in the flow, including
> the triggering user's OAuth token, service token, and identity details.
> For the security model and recommended protections, see
> [security implications of `agent-config.yml`](security-considerations.md#security-implications-of-agent-configyml).

### Configure caching

To configure caching to speed up subsequent flow runs, configure the `agent-config.yml` file to
preserve files and directories between executions. Caching can be useful for dependency folders like `node_modules` or Python virtual environments.

#### Basic cache configuration

To cache specific paths, add the following to your `agent-config.yml` file:

```yaml
cache:
  paths:
    - node_modules/
    - .npm/
```

#### Cache with keys

You can use cache keys to create different caches for different scenarios. Cache keys help ensure that the cache is based on your project's state.

##### Use a string key

```yaml
cache:
  key: my-project-cache
  paths:
    - vendor/
    - .bundle/
```

##### Use file-based cache keys

Create dynamic cache keys based on file contents (like lock files). When these files change, a new cache is created. This generates a SHA checksum of the specified files:

```yaml
cache:
  key:
    files:
      - package-lock.json
      - yarn.lock
  paths:
    - node_modules/
```

##### Use a prefix with file-based keys

Combine a prefix with the SHA computed for the cache key files:

```yaml
cache:
  key:
    files:
      - package-lock.json
    prefix: $CI_JOB_NAME
  paths:
    - node_modules/
    - .npm/
```

In this example, if the job name is `test` and the SHA checksum is `abc123`, the cache key becomes `test-abc123`.

#### Cache limitations

- You can specify up to two files for cache key generation. If more files are specified, only the first two are used.
- The cache `paths` field is required. A cache configuration without paths has no effect.
- Cache keys support CI/CD variables in the `prefix` field.

### Configure ID tokens

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/224940) in GitLab 19.2.

{{< /history >}}

To authenticate with third-party services from a flow, configure
[ID tokens](../../../../ci/secrets/id_token_authentication.md).

ID tokens are JSON web tokens (JWT) that GitLab CI/CD generates and injects into the job that runs the flow
for keyless OpenID Connect (OIDC) authentication without storing long-lived credentials.
For example, you can use ID tokens to retrieve secrets from a secrets manager or sign binaries and Git commits.

To configure ID tokens, in the `agent-config.yml` file, add an `id_tokens` block.
Each token requires an `aud` (audience) claim:

```yaml
id_tokens:
  VAULT_ID_TOKEN:
    aud: https://vault.example.com

network_policy:
  allowed_domains:
    - vault.example.com
```

The `aud` claim can be a single string or a list of strings:

```yaml
id_tokens:
  MY_ID_TOKEN:
    aud:
      - https://first.service.example.com
      - https://second.service.example.com

network_policy:
  allowed_domains:
    - first.service.example.com
    - second.service.example.com
```

Each token is available in the flow job as an environment variable that uses the name of the token.
For the previous examples, the flow can use `$VAULT_ID_TOKEN` and `$MY_ID_TOKEN`.

If a token name matches a variable name declared elsewhere in your configuration, the ID token
takes precedence.

> [!warning]
> An ID token is a credential that grants access to any service that trusts its `aud` claim.
> Set the narrowest possible `aud` value for each token so that a compromised token can
> authenticate with as few services as possible. Because the configuration file is read from
> the default branch, apply the [recommended protections](security-considerations.md#recommended-protections) to control
> who can change which tokens a flow can request.

For more information about the token payload and how to configure trust with third-party services,
see [OpenID Connect (OIDC) authentication using ID tokens](../../../../ci/secrets/id_token_authentication.md).

## Configure runners to execute flows

Flows that use CI/CD run on runners.

On GitLab.com, flows can use [hosted runners](../../../../ci/runners/hosted_runners/_index.md), which GitLab provides. These are enabled by default.

You also have the option to configure your own runner for flows.

> [!note]
> If your top-level group has [IP address restrictions](../../../group/access_and_permissions.md#restrict-group-access-by-ip-address)
> enabled, hosted runners cannot be used for flows. Hosted runners use dynamic IP addresses
> from cloud provider pools that cannot be added to your group's IP allowlist. Instead,
> configure your own group runner at the top-level group.

To configure your own runner for flows:

1. Create an [instance runner](../../../../ci/runners/runners_scope.md) or a group runner assigned to the top-level group. If you want flows to use project runners or group runners assigned to a subgroup, turn off the `duo_runner_restrictions` feature flag (GitLab Self-Managed only).
1. Add the `gitlab--duo` tag to the runner so that it picks up jobs for flows. If the runner does not have this tag, jobs with flows remain queued indefinitely.
   Use any of the following methods:
   - When you create the runner, in the **Tags** field, enter `gitlab--duo`.
   - For an existing runner, [edit the jobs the runner can run](../../../../ci/runners/configure_runners.md#control-jobs-that-a-runner-can-run)
     and enter `gitlab--duo` in the **Tags** field.
   - If you configure runners with a `config.toml` file, add the tag to the `[[runners]]` section:

     <!-- markdownlint-disable MD044 -->
     ```toml
     [[runners]]
       executor = "docker"
       tags = ["gitlab--duo"]
     ```
     <!-- markdownlint-enable MD044 -->

1. Configure the runner to use an [executor](https://docs.gitlab.com/runner/executors/) that
   supports Docker images, like `docker`, `docker-autoscaler`, or `kubernetes`.
   The `shell` executor is not supported.
1. If your top-level group has turned on [IP address restrictions](../../../group/access_and_permissions.md#restrict-group-access-by-ip-address),
   add the runner's IP address to your group's IP allowlist so the runner can access the group.
1. GitLab Self-Managed only. Ensure the runner can reach the services that flows require:
   - [Allow outbound connections from the GitLab instance](../../../../administration/gitlab_duo/configure/_index.md#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo) to the Agent Platform.
   - [Allow outbound connections from the runner](../../../../administration/gitlab_duo/configure/_index.md#allow-connections-from-the-runner) to the Agent Platform.
   - For instances with self-signed certificates in the certificate chain, complete the
     [additional GitLab Duo CLI configuration](../../../gitlab_duo_cli/use.md#certificate-errors).

### Use the execution environment sandbox to secure flows

For network and file system isolation, use the [execution environment sandbox](../../environment_sandbox.md)
to secure flows executed on runners.

To use the sandbox, you must use one of the following images:

- Default Docker base image for the Agent Platform
- A [custom image with SRT installed](../../environment_sandbox.md#install-anthropic-sandbox-runtime-srt-on-a-custom-image)

To configure runners to use the sandbox, set `privileged = true` in your [runner configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration/).

For example:

<!-- markdownlint-disable MD044 -->
```toml
[[runners]]
  executor = "docker"
  tags = ["gitlab--duo"]
  [runners.docker]
    privileged = true
```
<!-- markdownlint-enable MD044 -->

You cannot use the sandbox with the following images:

- Custom images without SRT installed
- Hardened UBI 9 Minimal image
