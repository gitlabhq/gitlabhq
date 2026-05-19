---
stage: AI-powered
group: Custom Models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Deploy GitLab Duo Agent Platform Self-Hosted in an offline environment
description: Transfer container images and LLM model weights to your internal infrastructure to run GitLab Duo Self-Hosted without internet access
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- Self-hosted model support [generally available](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.9.
- Offline flow execution support [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/219672) in GitLab 18.9.

{{< /history >}}

> [!note]
> To set up an offline environment, you must receive an
> [opt-out exemption of cloud licensing](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/#offline-cloud-licensing)
> prior to purchase.
> For more details, contact your GitLab sales representative.

You can deploy GitLab Duo Agent Platform Self-Hosted in an offline environment
where your GitLab instance and runners have no access to the public
internet.
These instructions also apply to environments with limited
connectivity or restrictive firewall policies.

In an offline environment, you must manually transfer the AI Gateway
container image, LLM model weights, vLLM inference server image,
and Agent Platform Flows executor image to your internal
infrastructure.

To deploy the Agent Platform in an offline environment, complete the following steps:

1. Transfer container images to the internal registry
1. Transfer LLM model weights to the offline filesystem
1. Start the AI Gateway
1. Start vLLM
1. Configure the AI Gateway in GitLab Admin
1. Add the self-hosted model
1. Configure offline flow execution
1. Verify the deployment

## Prerequisites

- GitLab 18.9 or later with an [offline cloud license](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/#offline-cloud-licensing).
- A machine with internet connection to download artifacts.
- [skopeo](https://github.com/containers/skopeo) and
  [jq](https://jqlang.github.io/jq/) installed on
  the connected machine and the offline host
  (`dnf install --assumeyes skopeo jq` on Red Hat systems).
- A method to transfer files to the offline environment
  (physical media, cross-domain solution, or bastion host).
- A container registry in the offline environment. For example,
  the [GitLab container registry](../../user/packages/container_registry/_index.md),
  Harbor, or Nexus.
- For vLLM: NVIDIA GPU drivers, CUDA libraries, and the
  [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
  installed on the inference host.
  For offline installation options, see the
  [NVIDIA CUDA installation guide](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/).

> [!note]
> All commands on this page work with both Docker and Podman.
> Replace `docker` with `podman` where applicable.

## Required artifacts

All artifacts except LLM model weights are OCI container images.

### Container images

| Artifact | Source registry | Tag format | Approximate size |
|----------|----------------|------------|-----------------|
| AI Gateway | `registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway` | `self-hosted-vX.Y.Z-ee` | 340 MB |
| Agent Platform Flows executor | `registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image` | `vX.Y.Z` | 2-3 GB |
| vLLM inference server | `docker.io/vllm/vllm-openai` | `vX.Y.Z` (v0.18.1 or later) | 2-4 GB |

The AI Gateway tag uses your GitLab version number:
`self-hosted-v<your-gitlab-version>-ee`.

To check the current executor image version, run the following command:

```shell
skopeo list-tags \
  docker://registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image \
  | jq --raw-output '.Tags[]' | grep --extended-regexp '^v[0-9]' | sort --version-sort | tail --lines=1
```

ClickHouse is not required for GitLab Duo Agentic Chat, Code
Suggestions, GitLab Duo Code Review, and Agent Platform flows.
If you need analytics about GitLab Duo usage, you must also transfer and configure
[ClickHouse](../../integration/clickhouse.md)
(`docker.io/clickhouse/clickhouse-server`).

For FIPS-validated environments, use the AI Gateway FIPS image
instead of the standard image.
The FIPS image uses the same `self-hosted-vX.Y.Z-ee` tag format.
FIPS versioned tags are available in GitLab 18.10 and later.
For more information, see
[FIPS-validated images](../../install/install_ai_gateway.md#fips-validated-images).

### LLM model weights

LLM model weights are large files that vLLM reads directly from the
filesystem.
These files are not distributed as container images.

Mistral Small 24B (~48 GB) is used in the examples on this page.
It supports both Code Suggestions and GitLab Duo Chat.
For other model options and GPU requirements, see
[Supported models and hardware requirements](supported_models_and_hardware_requirements.md).

## Transfer container images

On a connected machine, save the required images as archives,
then load them into your internal registry on the offline side.

### Save images on the connected machine

To save images, run `skopeo` on the machine connected to the internet with the following command:

```shell
GITLAB_VERSION="18.10.0"
EXECUTOR_VERSION="v0.0.6"
VLLM_VERSION="v0.18.1"

skopeo copy \
  docker://registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:self-hosted-v${GITLAB_VERSION}-ee \
  docker-archive:aigw.tar

skopeo copy \
  docker://registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:${EXECUTOR_VERSION} \
  docker-archive:executor.tar

skopeo copy \
  docker://docker.io/vllm/vllm-openai:${VLLM_VERSION} \
  docker-archive:vllm.tar
```

If your connected machine uses a proxy, set `HTTPS_PROXY` before
running `skopeo`:

```shell
export HTTPS_PROXY="http://proxy.example.com:8080"
```

Alternatively, use `docker save` if skopeo is not available:

```shell
GITLAB_VERSION="18.10.0"

docker pull registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:self-hosted-v${GITLAB_VERSION}-ee
docker save \
  registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:self-hosted-v${GITLAB_VERSION}-ee \
  --output aigw.tar
```

### Load images into the internal registry

Transfer the archives to the offline environment, then load them
into your internal registry.

> [!note]
> Shell variables do not persist across machines.
> Set `INTERNAL_REGISTRY`, `GITLAB_VERSION`, `EXECUTOR_VERSION`,
> and `VLLM_VERSION` again on the offline host.

If your internal registry uses a self-signed certificate, configure
skopeo to trust it:

```shell
mkdir --parents /etc/containers/certs.d/<registry-host>
cp ca.crt /etc/containers/certs.d/<registry-host>/ca.crt
```

Then load the images:

```shell
INTERNAL_REGISTRY="registry.internal.example.com/duo"
GITLAB_VERSION="18.10.0"
EXECUTOR_VERSION="v0.0.6"
VLLM_VERSION="v0.18.1"

skopeo copy \
  docker-archive:aigw.tar \
  docker://${INTERNAL_REGISTRY}/ai-gateway:self-hosted-v${GITLAB_VERSION}-ee

skopeo copy \
  docker-archive:executor.tar \
  docker://${INTERNAL_REGISTRY}/workflow-generic-image:${EXECUTOR_VERSION}

skopeo copy \
  docker-archive:vllm.tar \
  docker://${INTERNAL_REGISTRY}/vllm-openai:${VLLM_VERSION}
```

## Transfer LLM model weights

On a connected machine, to download the model weights, use either
the Hugging Face CLI or `git lfs`.

With the Hugging Face CLI:

```shell
pip install huggingface_hub
huggingface-cli download mistralai/Mistral-Small-3.2-24B-Instruct-2506 \
  --local-dir ./mistral-small-3.2-24b
```

If `huggingface-cli` is not available in your version of `huggingface_hub`,
use `hf download` with the same arguments.

With `git lfs` (no Python required):

```shell
dnf install --assumeyes git-lfs  # On Debian/Ubuntu: apt-get install git-lfs
git lfs install
git clone https://huggingface.co/mistralai/Mistral-Small-3.2-24B-Instruct-2506
```

Transfer the downloaded directory to the offline environment and
place it on a filesystem path accessible to the vLLM container
(for example, `/data/models/mistral-small-3.2-24b`).

## Start the AI Gateway

To run the AI Gateway container with your internal registry image:

1. Generate the required JWT signing keys:

   ```shell
   openssl genrsa -out aigw_signing.key 2048
   openssl genrsa -out aigw_validation.key 2048
   openssl genrsa -out duo_workflow_jwt.key 2048
   openssl genrsa -out duo_workflow_validation.key 2048
   ```

1. Run the AI Gateway container using your internal registry image:

   ```shell
   INTERNAL_REGISTRY="registry.internal.example.com/duo"
   GITLAB_VERSION="18.10.0"
   GITLAB_DOMAIN="gitlab.internal.example.com"

   docker run --detach \
     --publish 5052:5052 \
     --publish 50052:50052 \
     --env AIGW_GITLAB_URL=https://${GITLAB_DOMAIN} \
     --env AIGW_GITLAB_API_URL=https://${GITLAB_DOMAIN}/api/v4/ \
     --env AIGW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat aigw_signing.key)" \
     --env AIGW_SELF_SIGNED_JWT__VALIDATION_KEY="$(cat aigw_validation.key)" \
     --env DUO_WORKFLOW_AUTH__ENABLED="true" \
     --env DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY="$(cat duo_workflow_jwt.key)" \
     --env DUO_WORKFLOW_SELF_SIGNED_JWT__VALIDATION_KEY="$(cat duo_workflow_validation.key)" \
     --env DUO_WORKFLOW_AUTH__OIDC_CUSTOMER_PORTAL_URL= \
     ${INTERNAL_REGISTRY}/ai-gateway:self-hosted-v${GITLAB_VERSION}-ee
   ```

When you set `DUO_WORKFLOW_AUTH__OIDC_CUSTOMER_PORTAL_URL=` to an empty string,
you prevent the AI Gateway from attempting to reach the CustomersDot service,
which is not available in offline environments. Without this setting, each
request experiences a 20-second delay.

For TLS termination and additional configuration options, see
[Install the GitLab AI Gateway](../../install/install_ai_gateway.md).

## Start vLLM

Run vLLM to serve your transferred model weights:

```shell
INTERNAL_REGISTRY="registry.internal.example.com/duo"
VLLM_VERSION="v0.18.1"

docker run --detach \
  --gpus all \
  --volume /data/models/mistral-small-3.2-24b:/model \
  --publish 8000:8000 \
  ${INTERNAL_REGISTRY}/vllm-openai:${VLLM_VERSION} \
  --model /model \
  --served_model_name custom_openai/mistral-small-3.2-24b \
  --tensor-parallel-size <number-of-gpus>
```

Replace `<number-of-gpus>` with the number of GPUs available.
For a single GPU, use `--tensor-parallel-size 1`.
For Podman, replace `--gpus all` with
`--device nvidia.com/gpu=all --security-opt label=disable`.
The `--security-opt label=disable` flag is required on
SELinux-enforcing systems for GPU device access.

After startup, verify the model is loaded:

```shell
curl --silent "http://localhost:8000/v1/models"
```

- For more information about vLLM configurations, see
  [Supported LLM serving platforms](supported_llm_serving_platforms.md).
- For information about how to deploy vLLM, see
  [Example model deployment with vLLM](vllm_gpt_oss_120b.md).

## Configure the AI Gateway in GitLab

After the AI Gateway and vLLM are running, configure GitLab to use them:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **GitLab Duo**.
1. Select **Change configuration**.
1. Under **Local AI Gateway URL**, enter `http://<ai-gateway-host>:5052`.
1. Under **Local URL for the GitLab Duo Agent Platform service**,
   enter `<ai-gateway-host>:50052`.
1. Turn on **GitLab Duo Agent Platform**.
   After you turn it on, the **Flow execution** section expands.
1. Under **Image registry**, enter your internal registry URL
   (for example, `registry.internal.example.com/duo`).
1. Select **Save changes**.

## Add the self-hosted model

Add the self-hosted model deployment to your GitLab instance:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **GitLab Duo**.
1. Select **Configure models for GitLab Duo**.
1. Select **Add self-hosted model**.
1. Complete the fields:
   - For **Endpoint**, enter the URL of your vLLM server.
   - For **Model identifier**, enter
     `custom_openai/mistral-small-3.2-24b`.
1. Optional. Select **Test connection** to verify the AI Gateway
   can reach the vLLM endpoint.
1. Select **Add self-hosted model**.

## Configure offline flow execution

For offline flow execution, use a custom executor image with
`duo-cli` pre-installed.

1. Build the custom image on a connected machine:

   ```dockerfile
   FROM registry.gitlab.com/gitlab-org/duo-workflow/default-docker-image/workflow-generic-image:v0.0.6
   RUN npm install --global @gitlab/duo-cli@8.86.0
   ```

   To find the current `duo-cli` version, check the `DUO_CLI_VERSION`
   constant in the GitLab Rails source or the
   [GitLab Duo CLI npm page](https://www.npmjs.com/package/@gitlab/duo-cli).

1. Transfer the image to your internal registry using the same
   `skopeo copy` procedure described above, then reference it
   in your project's `agent-config.yml`:

   ```yaml
   image: registry.internal.example.com/duo/duo-executor:v0.0.6
   ```

## Verify the deployment

1. Confirm that the AI Gateway is running:

   ```shell
   curl --silent "http://<ai-gateway-host>:5052/monitoring/healthz"
   ```

1. Run the GitLab Duo health check:
   1. In the upper-right corner, select **Admin**.
   1. In the left sidebar, select **GitLab Duo**.
   1. Select **Run health check**.

   The health check validates AI Gateway connectivity and license
   status.
   It does not test model inference.

1. To verify model inference, send a test request through GitLab Duo Chat
   or Code Suggestions in the GitLab UI or an IDE.

1. To verify Agent Platform Flows, trigger a flow and confirm that
   the executor image is pulled from your internal registry and
   `duo-cli` is not downloaded from npm.

For common issues, see
[Troubleshooting](troubleshooting.md).

## Update artifacts

When you upgrade your GitLab instance, transfer updated container
images using the same procedure.
Use the AI Gateway image tag that matches the new GitLab version.

Model weights do not need to be updated when you upgrade GitLab.
Updates are only required when you change to a different model.

## Related topics

- [Offline GitLab](../../topics/offline/_index.md)
- [Self-hosted models](_index.md)
