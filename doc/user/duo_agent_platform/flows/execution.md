---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configure flow execution
---

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/477166) in GitLab 18.3.

{{< /history >}}

Flows use agents to execute tasks.

- Flows executed from the GitLab UI use CI/CD.
- Flows executed in an IDE run locally.

You can configure the environment where flows use CI/CD to execute.
You can also choose to [use your own runners](#configure-runners-to-execute-flows), and
[specify variables in your jobs](execution_variables.md).

## Flow security

When flows execute in GitLab CI/CD:

- They use a [composite identity](../composite_identity.md) to limit access.
- They create an ephemeral [workload pipieline](../../../ci/pipelines/pipeline_types.md#workload-pipeline),
  which is removed when the flow is complete.
- The tools at their disposal are specific to the purpose of the flow.
  These tools can include the creation of merge requests or the running of local shell commands in their execution environment.

By default, flows have network access to the GitLab instance only.
For more information about network access rules, see [how to configure a network policy](../environment_sandbox.md#configure-a-network-policy).
This separate environment protects from unintended consequences of running shell commands.

To prevent flows from running autonomously in the GitLab UI, you can [turn off flow execution](foundational_flows/_index.md#turn-foundational-flows-on-or-off).

### Security implications of `agent-config.yml`

The `.gitlab/duo/agent-config.yml` file controls how flows execute in CI/CD, including the
commands that run in `setup_script`. Because of how flows run, changes to this file affect more
than the user who commits them.

#### Cross-user execution

Flows run under the identity of the user who triggers them through [composite identity](../composite_identity.md).
Commands in `setup_script` execute with the triggering user's composite identity credentials,
not the credentials of the user who committed the configuration.

A user with write access to `.gitlab/duo/agent-config.yml` can influence what runs in another
user's runner environment. Modifications to this file affect the execution context of every
user who later triggers a flow in the project.

#### Exposed environment variables

During `setup_script` execution, which runs outside Anthropic Sandbox Runtime (SRT),
the following sensitive variables are present in the environment:

- `GITLAB_OAUTH_TOKEN` and `GITLAB_TOKEN`: The triggering user's OAuth token
  through composite identity.
- `DUO_WORKFLOW_GIT_HTTP_PASSWORD`: The Git HTTP password.
- `DUO_WORKFLOW_SERVICE_TOKEN`: The service token.
- `DUO_WORKFLOW_GIT_USER_EMAIL` and `DUO_WORKFLOW_GIT_USER_NAME`: The triggering user's
  email and name.

For the full list of exposed variables, see [flow execution variables](execution_variables.md).

#### Recommended protections

To reduce the risk of unauthorized changes to the `.gitlab/duo/agent-config.yml` file:

- [Protect your default branch](../../../user/project/repository/branches/protected.md) to prevent direct pushes.
- Use [Code Owners](../../../user/project/codeowners/_index.md) to require approval from specific
  owners before changes to `.gitlab/duo/agent-config.yml` are merged.
  For example, add the following to your `CODEOWNERS` file:

  ```plaintext
  .gitlab/duo/agent-config.yml @your-group/security-reviewers
  ```

- Configure [approval rules](../../../user/project/merge_requests/approvals/rules.md) that require
  review from trusted maintainers for merge requests that modify this file.

## Executor architecture

When a flow runs in CI/CD, the runner:

1. Downloads the `@gitlab/duo-cli` package from the npm registry.
1. Runs the GitLab Duo CLI, which uses WebSocket to connect to the GitLab Duo Workflow Service.
1. Executes tools (file operations, Git commands) as directed by the AI model.

The executor version is managed by GitLab and updated as part of regular releases.

## Configure CI/CD execution

You can customize how flows are executed in CI/CD by creating an agent configuration file in your project.

> [!note]
> You cannot use predefined CI/CD variables in this scenario.
> See [the list of available variables](execution_variables.md#available-variables).

## Create the configuration file

1. In your project's repository, create a `.gitlab/duo/` folder if it doesn't exist.
1. In the folder, create a configuration file named `agent-config.yml`.
1. Add your required configuration options (see sections below).
1. Commit and push the file to your default branch.

The configuration is applied when flows run in CI/CD for your project.

> [!note]
> The configuration file is read only from the project's default branch.
> Files committed to other branches are ignored, even when a flow runs from those branches.

### Change the default Docker image

By default, all flows executed with CI/CD use a standard Docker image provided by GitLab.
This Docker image uses [Anthropic Sandbox Runtime (`srt`)](https://github.com/anthropic-experimental/sandbox-runtime)
to automatically include network protection.

You can change the Docker image and specify your own instead.
Your own image can be useful for complex projects that require specific dependencies or tools.
To use network protection in your image, add `srt` to your
Docker image with your preferred version:

```Docker
# Install srt sandboxing with cache clearing and verification
ARG SANDBOX_RUNTIME_VERSION=0.0.20
RUN npm cache clean --force && \
    npm install -g @anthropic-ai/sandbox-runtime@${SANDBOX_RUNTIME_VERSION} && \
    test -s "$(npm root -g)/@anthropic-ai/sandbox-runtime/package.json" && \
    srt --version
```

For more information about SRT and how to install it on a custom image, see [remote execution environment sandbox](../environment_sandbox.md).

To change the default Docker image, in the `agent-config.yml` file, add the following configuration:

```yaml
image: YOUR_DOCKER_IMAGE
```

For example:

```yaml
image: python:3.11-slim
```

Or for a Node.js project:

```yaml
image: node:20-alpine
```

#### Hardened UBI 9 Minimal image

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/-/merge_requests/12) in GitLab 19.0.

{{< /history >}}

GitLab also provides a hardened, minimal image variant based on Red Hat Universal Base Image (UBI) 9 Minimal.
This image is designed for network-restricted, FedRAMP-style, or otherwise security-sensitive environments
where a smaller attack surface, non-root execution, and a Red Hat UBI base are required.

The hardened image is published at:
`registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened`

It is built for both `linux/amd64` and `linux/arm64`, and uses the same tag scheme as the default image:

- `:<short-sha>` per build
- `:<git-tag>` per release

##### Use the hardened image

Prerequisites:

- GitLab 18.10 or later

To use the hardened image, set it in your `agent-config.yml`:

```yaml
image: registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened:<tag>
```

##### Image contents

| Component           | Version                           |
|---------------------|-----------------------------------|
| Base image          | Red Hat UBI 9 Minimal             |
| `git`               | UBI 9 stock                       |
| `git-lfs`           | UBI 9 stock                       |
| Node.js             | 20 (UBI 9 module stream)          |
| `npm`               | Bundled with Node.js 20           |
| `@gitlab/duo-cli`   | Pre-installed                     |
| `glab` (GitLab CLI) | Pre-installed                     |
| Runtime user        | Non-root, UID 1001 (`duo-runner`) |

The image includes `@gitlab/duo-cli` and `glab`, so outbound access to `registry.npmjs.org` or `registry.gitlab.com` is not needed at flow execution time.

##### Extend the image with additional packages

The hardened image runs as UID 1001 (`duo-runner`). The `setup_script` in your `agent-config.yml`
also runs as this non-root user, so it cannot install system packages with `microdnf`.

To add language runtimes or system packages:

1. Extend the image with your own `FROM` layer:

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened:<tag>

   USER root
   RUN microdnf install -y python3.12 python3.12-pip && microdnf clean all
   USER 1001
   ```

1. Use `setup_script` for project dependencies that do not require root access. For example, `pip install --user` or `npm install`.

##### When to use the hardened image

Use the hardened image when your environment requires:

- A Red Hat UBI base image. For example, for FedRAMP or enterprise compliance.
- Non-root container execution by default.
- A minimal attack surface with no language runtimes beyond what the Agent Platform itself needs.
- No outbound internet access at flow execution time (all Agent Platform dependencies are pre-installed).

Use the [default image](#change-the-default-docker-image) for general-purpose flows on connected
environments that need multiple language runtimes out of the box.

#### Custom image requirements

If you use a custom Docker image, ensure that the following commands are available for the agent to function correctly:

- `git`
- `npm` with a Node.js version compatible with `@gitlab/duo-cli`. For more information, see [GitLab Duo CLI prerequisites](../../gitlab_duo_cli/_index.md#install).

Most base images include these commands by default. However, minimal images (like `alpine` variants)
might require you to install them explicitly. If needed, you can install missing commands in the
[setup script configuration](#configure-setup-scripts).

> [!note]
> In GitLab 18.9 and earlier, there is [a known issue (587996)](https://gitlab.com/gitlab-org/gitlab/-/work_items/587996) where flows might fail with newer versions of `git` in custom images. This issue is resolved in `@gitlab/duo-cli` version 8.71.0.
>
> If you are on `@gitlab/duo-cli` version 8.71.0 or earlier, to avoid flows failing with newer Git versions, you can do either of the following:
>
> - Use Git version `2.43.7` or earlier in your custom image
> - Use `@gitlab/duo-cli` version 8.71.0.

Additionally, depending on the tool calls made by agents during flow execution, other common utilities might be required.

For example, if you use an Alpine-based image:

```yaml
image: python:3.11-alpine
setup_script:
  - apk add --update git nodejs npm
```

#### Security and performance

When you use a custom Docker image, the
[environment sandbox](../environment_sandbox.md) is only applied when Anthropic Sandbox Runtime (SRT)
is included in your custom image. If SRT is not included, your flow
can access any domain reachable from the runner and the full filesystem.

If you require network isolation with custom images, [install SRT on your image](../environment_sandbox.md#install-anthropic-sandbox-runtime-srt-on-a-custom-image)
and [configure a network policy](../environment_sandbox.md#configure-a-network-policy), or configure network-level controls on your runner
(for example, firewall rules or network policies).

To reduce job startup time by approximately 15-20 seconds, include the
`@gitlab/duo-cli` npm package and the `glab` CLI in your custom image.
The hardened image pre-installs both tools.

### Configure setup scripts

You can define setup scripts that run before your flow executes. This is useful for installing dependencies, configuring environments, or performing any necessary initialization.

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
> [security implications of `agent-config.yml`](#security-implications-of-agent-configyml).

### Use a custom image in an offline environment

In offline environments where runners cannot reach external
registries, you can prebuild a custom executor image that includes
`@gitlab/duo-cli`. When the GitLab Duo CLI is already in the image, the
flow startup skips the npm download step.

Prerequisites:

- Administrator access.
- GitLab 18.9 or later.
- Access to an online machine to build the image and download artifacts.

To configure flows for an offline environment:

1. On an online machine, build a custom image with the GitLab Duo CLI:

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:v0.0.6
   RUN npm install -g @gitlab/duo-cli@8.86.0
   ```

   Alternatively, to avoid npm entirely, download the standalone binary
   from the [GitLab package registry](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/packages):

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:v0.0.6
   COPY duo-linux-x64 /usr/bin/duo
   RUN chmod +x /usr/bin/duo
   ```

   To download the standalone binary, run the following command:

   ```shell
   curl --location "https://gitlab.com/api/v4/projects/46519181/packages/generic/duo-cli/8.86.0/duo-linux-x64" \
     --output duo-linux-x64
   ```

1. Transfer the image to your offline environment.
   For example, with Docker, run the following commands:

   ```shell
   # On an online machine
   docker save my-duo-executor:latest -o duo-executor.tar

   # Transfer `duo-executor.tar` to the offline environment

   # On an offline machine
   docker load -i duo-executor.tar
   ```

1. Push the image to your internal container registry.
1. Set the custom image registry:
   1. In the upper-right corner, select **Admin**.
   1. In the left sidebar, select **GitLab Duo**.
   1. Select **Change configuration**.
   1. In the **Image registry** text box, enter your internal registry URL
      (for example, `registry.internal.example.com`).
1. In the top bar, select **Search or go to** and find your project.
1. To use the custom image, update the `agent-config.yml` file:

   ```yaml
   image: registry.internal.example.com/duo-executor:latest
   ```

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
[ID tokens](../../../ci/secrets/id_token_authentication.md).

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
> the default branch, apply the [recommended protections](#recommended-protections) to control
> who can change which tokens a flow can request.

For more information about the token payload and how to configure trust with third-party services,
see [OpenID Connect (OIDC) authentication using ID tokens](../../../ci/secrets/id_token_authentication.md).

### Complete configuration example

Here's an example `agent-config.yml` file that uses all available options:

```yaml
# Custom Docker image
image: python:3.11

# Setup script to run before the flow
setup_script:
  - apt-get update && apt-get install -y build-essential
  - pip install --upgrade pip
  - pip install -r requirements.txt

# Cache configuration
cache:
  key:
    files:
      - requirements.txt
      - Pipfile.lock
    prefix: python-deps
  paths:
    - .cache/pip
    - venv/

# Network configuration
network_policy:
  include_recommended_allowed: true
  allow_all_unix_sockets: true
  allowed_domains:
    - vault.example.com
  denied_domains:
    - malicious.com

# ID tokens for OIDC authentication
id_tokens:
  VAULT_ID_TOKEN:
    aud: https://vault.example.com
```

This configuration:

- Uses Python 3.11 as the base image.
- Installs build tools and Python dependencies before running the flow.
- Caches pip and virtual environment directories.
- Creates a new cache when `requirements.txt` or `Pipfile.lock` changes, with a prefix of `python-deps`.
- Provides a `VAULT_ID_TOKEN` ID token for OIDC authentication with HashiCorp Vault.

## Configure runners to execute flows

Flows that use CI/CD run on runners.

On GitLab.com, flows can use [hosted runners](../../../ci/runners/hosted_runners/_index.md), which GitLab provides. These are enabled by default. 

You also have the option to configure your own runner for flows.

> [!note]
> If your top-level group has [IP address restrictions](../../group/access_and_permissions.md#restrict-group-access-by-ip-address)
> enabled, hosted runners cannot be used for flows. Hosted runners use dynamic IP addresses
> from cloud provider pools that cannot be added to your group's IP allowlist. Instead,
> configure your own group runner at the top-level group.

To configure your own runner for flows:

1. Create an [instance runner](../../../ci/runners/runners_scope.md) or a group runner assigned to the top-level group. If you want flows to use project runners or group runners assigned to a subgroup, turn off the `duo_runner_restrictions` feature flag (GitLab Self-Managed only).
1. Add the `gitlab--duo` tag to the runner so that it picks up jobs for flows. If the runner does not have this tag, jobs with flows remain queued indefinitely.
   Use any of the following methods:
   - When you create the runner, in the **Tags** field, enter `gitlab--duo`.
   - For an existing runner, [edit the jobs the runner can run](../../../ci/runners/configure_runners.md#control-jobs-that-a-runner-can-run)
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
1. If your top-level group has turned on [IP address restrictions](../../group/access_and_permissions.md#restrict-group-access-by-ip-address),
   add the runner's IP address to your group's IP allowlist so the runner can access the group.
1. GitLab Self-Managed only. Ensure the runner can reach the services that flows require:
   - [Allow outbound connections from the GitLab instance](../../../administration/gitlab_duo/configure/_index.md#allow-outbound-connections-from-the-gitlab-instance-to-gitlab-duo) to the Agent Platform.
   - [Allow outbound connections from the runner](../../../administration/gitlab_duo/configure/_index.md#allow-connections-from-the-runner) to the Agent Platform.
   - For instances with self-signed certificates in the certificate chain, complete the
     [additional GitLab Duo CLI configuration](../../gitlab_duo_cli/_index.md#custom-ssl-certificates).

### Use the execution environment sandbox to secure flows

For network and file system isolation, use the [execution environment sandbox](../environment_sandbox.md)
to secure flows executed on runners.

To use the sandbox, you must use one of the following images:

- Default Docker base image for the Agent Platform
- A [custom image with SRT installed](../environment_sandbox.md#install-anthropic-sandbox-runtime-srt-on-a-custom-image)

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
