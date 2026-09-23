---
stage: Agent Foundations
group: Agent Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Replace the default Docker image with a custom, hardened, or offline image to run GitLab Duo Agent Platform flows in CI/CD.
title: Configure images for flow execution
---

{{< details >}}

- Tier: [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Flows that run with CI/CD execute inside a Docker image. By default, GitLab provides
an image that includes the tools and network protection flows need. You can replace
the default image with a custom or hardened image to add project dependencies, meet compliance
requirements, or run flows in an offline environment.

## Change the default Docker image

All flows executed with CI/CD use a Docker image provided by GitLab.
This Docker image uses [Anthropic Sandbox Runtime (`srt`)](https://github.com/anthropic-experimental/sandbox-runtime)
to automatically include network protection.

You can change the Docker image if you have a complex project with specific dependencies
or tools.

To change the default Docker image, in the `agent-config.yml` file, add the following configuration:

```yaml
image: YOUR_DOCKER_IMAGE
```

For example:

{{< tabs >}}

{{< tab title="Python project" >}}

```yaml
image: python:3.11-slim
```

{{< /tab >}}

{{< tab title="Node.js project" >}}

```yaml
image: node:20-alpine
```

{{< /tab >}}

{{< /tabs >}}

### Add network protection

To use network protection in your image, add `srt` to your
Docker image with your preferred version:

```Docker
# Install srt sandboxing with cache clearing and verification
ARG SANDBOX_RUNTIME_VERSION=0.0.63
RUN npm cache clean --force && \
    npm install -g @anthropic-ai/sandbox-runtime@${SANDBOX_RUNTIME_VERSION} && \
    test -s "$(npm root -g)/@anthropic-ai/sandbox-runtime/package.json" && \
    srt --version
```

For more information about SRT and how to install it on a custom image, see [remote execution environment sandbox](../../environment_sandbox.md).

## Use a custom image

If you use a custom Docker image, ensure that the following commands are available for the agent to function correctly:

- `git`
- `curl`, which downloads the GitLab Duo CLI binary at flow startup.

Most base images include these commands by default. However, minimal images (like `alpine` variants)
might require you to install them explicitly. If needed, you can install missing commands in the
[setup script configuration](_index.md#configure-setup-scripts).

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
  - apk add --update git curl
```

### Security and performance

When you use a custom Docker image, the
[environment sandbox](../../environment_sandbox.md) is only applied when Anthropic Sandbox Runtime (SRT)
is included in your custom image. If SRT is not included, your flow
can access any domain reachable from the runner and the full file system.

If you require network isolation with custom images, [install SRT on your image](../../environment_sandbox.md#install-anthropic-sandbox-runtime-srt-on-a-custom-image)
and [configure a network policy](../../environment_sandbox.md#configure-a-network-policy), or configure network-level controls on your runner
(for example, firewall rules or network policies).

To reduce job startup time by approximately 15-20 seconds, include the
GitLab Duo CLI binary and the `glab` CLI in your custom image.
The hardened image pre-installs both tools.

## Use a custom image in an offline environment

In offline environments where runners cannot reach external
registries, you can prebuild a custom executor image that includes
the GitLab Duo CLI. When the GitLab Duo CLI is already in the image, the
flow startup skips the download step.

Prerequisites:

- Administrator access.
- GitLab 18.9 or later.
- Access to an online machine to build the image and download artifacts.

To configure flows for an offline environment:

1. On an online machine, download the GitLab Duo CLI binary from the
   [GitLab package registry](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/packages):

   ```shell
   curl --location "https://gitlab.com/api/v4/projects/46519181/packages/generic/duo-cli/9.8.0/duo-linux-x64" \
     --output duo-linux-x64
   ```

1. Build a custom image that includes the binary:

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:v0.0.6
   COPY duo-linux-x64 /usr/bin/duo
   RUN chmod +x /usr/bin/duo
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

### Configure flows to pull the image from the GitLab container registry

If you push the image to a project's container registry on the same GitLab
instance, a flow's CI/CD job pulls it across projects. That pull fails until
you configure it, because the job runs as the
[service account](../../composite_identity.md) GitLab creates for flows, and
GitLab creates that account as an
[external user](../../../../administration/external_users.md). An internal
project looks private to an external account, so the registry refuses the
pull.

Two conditions must both hold for the pull to succeed. The service account
must be able to read the host project's container registry, and so must the
person who triggers the flow.
[Composite identity](../../composite_identity.md) limits the service account
to the access of that person, so a flow never has permissions the triggering
user lacks. Satisfying one condition alone leaves the pull refused.

To give the service account access, either make it non-external, or make it a
member of the host project.

To make the account non-external:

1. Set the project that hosts the image to
   [internal visibility](../../../public_access.md#change-project-visibility).
   Set the container registry visibility to **Everyone With Access**. If you select **Only Project Members**, the pull fails. For more information, see
   [Configure project features and permissions](../../../project/settings/_index.md#configure-project-features-and-permissions).
1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Overview** > **Users**.
1. Find the service account GitLab created for flows, then select **Edit**.
1. In the **Access** section, clear the **External** checkbox.
1. Select **Save changes**.

To make the account a member of the host project instead:

1. Add the service account to the host project as a member with at least the
   Developer role.
1. Add the project that runs the flow to the host project's
   [job token allowlist](../../../../ci/jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist).

Membership without the allowlist entry is not enough.

The people who trigger flows need access to the host project by the same
rules as any other user. On an internal host project, they must not be
external users. On a private host project, they must be members with at least
the Reporter role. The Guest role is not enough, because a Guest can see the
project but cannot pull from its container registry.

### Provide credentials for the image pull

If the registry that contains the image requires credentials, configure them on
the runner that runs the flow's jobs. You can configure credentials on registries
that GitLab hosts and does not host.
By default, a flow's job does not receive CI/CD variables configured at the
project, group, or instance level, so a `DOCKER_AUTH_CONFIG` variable defined
there does not apply, and the value cannot be
[masked](../../../../ci/variables/_index.md#mask-a-cicd-variable).

To supply credentials on the runner:

1. On the project that hosts the image, create a
   [deploy token](../../../project/deploy_tokens/_index.md#pull-images-from-a-container-registry)
   with the `read_registry` scope.
1. [Add `DOCKER_AUTH_CONFIG` to the runner](../../../../ci/docker/using_docker_images.md#configuring-a-runner)
   as an entry in the `environment` list of the `[[runners]]` section of its
   `config.toml` file.

## Use a Red Hat Universal Base Image 9 Minimal

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/-/merge_requests/12) in GitLab 19.0.

{{< /history >}}

GitLab provides a hardened, minimal image variant based on Red Hat Universal Base Image (UBI) 9 Minimal.

Use the hardened image when your environment requires:

- A Red Hat UBI base image. For example, for FedRAMP or enterprise compliance.
- Non-root container execution by default.
- A minimal attack surface with no language runtimes beyond what the Agent Platform itself needs.
- No outbound internet access at flow execution time (all Agent Platform dependencies are pre-installed)

The hardened image is published at
`registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened`

It is built for both `linux/amd64` and `linux/arm64`, and uses the following tag scheme:

- `:<short-sha>` for each build
- `:<git-tag>` for each release

Prerequisites:

- GitLab 18.10 or later

To use the hardened image, set it in your `agent-config.yml`:

```yaml
image: registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image-hardened:<tag>
```

### Image contents

For the authoritative and up-to-date list of all components and pinned versions,
see the runtime inventory in the `default-docker-image` [README](https://gitlab.com/gitlab-org/duo-workflow/default-docker-image/-/blob/main/README.md#runtime-inventory).

The following table lists the current pinned versions:

| Component                             | Version or source                                        |
|---------------------------------------|----------------------------------------------------------|
| Base image                            | Red Hat UBI 9 Minimal (`ubi9-minimal:9.7-1776833838`)    |
| `git`                                 | 2.47.x (UBI 9 stock)                                     |
| `git-lfs`                             | UBI 9 stock                                              |
| Node.js                               | 20 (UBI 9 module stream `nodejs:20`)                     |
| `npm`                                 | Bundled with Node.js 20                                  |
| `@gitlab/duo-cli`                     | 9.21.0                                                   |
| `glab` (GitLab CLI)                   | 1.107.0                                                  |
| `@anthropic-ai/sandbox-runtime` (SRT) | 0.0.63 (via npm)                                         |
| `bwrap` (bubblewrap)                  | AlmaLinux 9 EPEL (plain binary, userns-based sandboxing) |
| `socat`                               | AlmaLinux 9 EPEL                                         |
| `rg` (ripgrep)                        | AlmaLinux 9 EPEL                                         |
| `unshare`                             | UBI 9 (`util-linux-core`)                                |
| Runtime user                          | Non-root, UID 1001 (`duo-runner`)                        |

The image includes the GitLab Duo CLI and `glab`. Outbound access to `registry.npmjs.org` or `registry.gitlab.com`
is not needed at flow execution time.

Node.js and `npm` remain in the image only to install the Anthropic Sandbox Runtime (SRT).
The GitLab Duo CLI itself is a precompiled binary and does not need them. When SRT is also
distributed as a precompiled binary, a later version of the hardened image drops Node.js
and `npm` entirely.

### Add additional packages

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
