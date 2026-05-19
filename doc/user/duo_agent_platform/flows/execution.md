---
stage: AI-powered
group: Agent Foundations
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
You can also choose to [use your own runners](#configure-runners), and
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

## Executor architecture

When a flow runs in CI/CD, the runner:

1. Downloads the `@gitlab/duo-cli` package from the npm registry.
1. Runs the GitLab Duo CLI, which uses WebSocket to connect to the GitLab Duo Workflow Service.
1. Executes tools (file operations, Git commands) as directed by the AI model.

The executor version is managed by GitLab and updated as part of regular releases.

> [!note]
> The `@gitlab/duo-cli` npm package is labeled "Experimental" for standalone CLI usage.
> When used within flows, the relevant capabilities are covered by the same support level as flows.

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
`@gitlab-org/duo-cli` npm package and the `glab` CLI in your custom image. This skips the download steps for these during flow startup.
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

> [!note]
> The user context for `setup_script` depends on the Docker image. The default
> GitLab image runs as `root`. Custom images run as the user defined in the
> image's `USER` directive. If your `setup_script` requires root access (for
> example, to install system packages), ensure your custom image is configured
> accordingly.

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
    - my-own-site.com
  denied_domains:
    - malicious.com
```

This configuration:

- Uses Python 3.11 as the base image.
- Installs build tools and Python dependencies before running the flow.
- Caches pip and virtual environment directories.
- Creates a new cache when `requirements.txt` or `Pipfile.lock` changes, with a prefix of `python-deps`.

## Configure runners

Flows that use CI/CD are executed on runners. These runners must:

- Use an [executor](https://docs.gitlab.com/runner/executors/) that supports Docker images.
  For example, `docker`, `docker-autoscaler`, `kubernetes`, or others.
  The `shell` executor is not supported.
- Have the `gitlab--duo` tag, so the runner knows to pick up the correct jobs.
- Be instance runners or assigned to the top-level group. Flows cannot use runners configured for a subgroup or project. On GitLab Self-Managed this restriction can be disabled by disabling the `duo_runner_restrictions` feature flag.

In addition, the following requirements apply to runners on GitLab Self-Managed:

- Runners must allow network traffic to the GitLab Duo Agent Platform Service configured for the GitLab instance.
  - The GitLab Duo Agent Platform Service ships with the [AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist). If you self-host the AI Gateway and don't set a local URL for the Agent Platform, agentic features route traffic to `duo-workflow-svc.runway.gitlab.net` on port `443`.
- Runners must be able to download the default image from `registry.gitlab.com`
  or be able to access [the Docker image you specified](#change-the-default-docker-image).

For GitLab instances with self-signed certificates in the certificate chain, the GitLab Duo CLI requires [additional configuration](../../gitlab_duo_cli/_index.md#custom-ssl-certificates).

> [!note]
> The runner's connection to the GitLab Duo Agent Platform Service is routed through the
> GitLab instance. Runners do not connect directly to
> `duo-workflow-svc.runway.gitlab.net`. The firewall requirement for
> `duo-workflow-svc.runway.gitlab.net` on port `443` applies to the GitLab
> instance, not the runner. Your runner network configuration must allow
> outbound HTTPS traffic to the GitLab instance.

On GitLab.com, flows can use:

- [Hosted runners](../../../ci/runners/hosted_runners/_index.md), which GitLab provides.

> [!note]
> If your top-level group has [IP address restrictions](../../group/access_and_permissions.md#restrict-group-access-by-ip-address)
> enabled, hosted runners cannot be used for flows. Hosted runners use dynamic IP addresses
> from cloud provider pools that cannot be added to your group's IP allowlist. Instead,
> configure your own group runner with the `gitlab--duo` tag at the top-level group level,
> and ensure its IP address is included in your group's allowlist.

Flows executed on runners can be secured with runtime sandboxing offering network and file system isolation. To benefit
from sandboxing you must:

1. Turn on [privileged](https://docs.gitlab.com/runner/security/#reduce-the-security-risk-of-using-privileged-containers)
   mode by setting `privileged = true` in your [runner configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration/).
1. Use either:
   - The default Docker base image for GitLab Duo Agent Platform
   - A [custom image with SRT installed](../environment_sandbox.md#install-anthropic-sandbox-runtime-srt-on-a-custom-image)

### Runner privileged mode

Privileged mode is required for [environment sandbox](../environment_sandbox.md) protection.
This requirement applies when you use either the default GitLab-provided image or a custom image with SRT installed.
If you use a custom Docker image without SRT, privileged mode is not required because the sandbox cannot be applied.

| Configuration | Privileged mode required | Sandbox active |
|---------------|-------------------------|----------------|
| Default image | Yes | Yes |
| [Custom image with SRT](../environment_sandbox.md#install-anthropic-sandbox-runtime-srt-on-a-custom-image) | Yes | Yes |
| Custom image without SRT | No | No |
| [Hardened UBI 9 Minimal image](#hardened-ubi-9-minimal-image) | No | No |
