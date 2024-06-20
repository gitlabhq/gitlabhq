---
stage: AI-Powered
group: Custom Models
description: Setup your Self-Hosted Model Deployment infrastructure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Set up your self-hosted model deployment infrastructure

DETAILS:
**Tier:** For a limited time, Premium and Ultimate. In the future, [GitLab Duo Enterprise](../../subscriptions/subscription-add-ons.md).
**Offering:** Self-managed
**Status:** Experiment

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../../administration/feature_flags.md) named `ai_custom_model`. Disabled by default.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

WARNING:
This feature is considered [experimental](../../policy/experiment-beta-support.md) and is not intended for customer usage outside of initial design partners. We expect major changes to this feature.

DISCLAIMER:
This page contains information related to upcoming products, features, and functionality.
It is important to note that the information presented is for informational purposes only.
Please do not rely on this information for purchasing or planning purposes.
The development, release, and timing of any products, features, or functionality may be subject to change or delay and remain at the
sole discretion of GitLab Inc.

By self-hosting the model, AI Gateway, and GitLab instance, there are no calls to external architecture, ensuring maximum levels of security.

To set up your self-hosted model deployment infrastructure:

1. Install the large language model (LLM) serving infrastructure.
1. Install the GitLab AI Gateway.

- [Installation video guide](https://youtu.be/UNmD9-sgUvw)
- [Installation video guide (French version)](https://www.youtube.com/watch?v=aU5vnzO-MSM)

## Step 1: Install LLM serving infrastructure

Install one of the following GitLab-approved LLM models:

- [Mistral-7B-v0.1](https://huggingface.co/mistralai/Mistral-7B-v0.1).
- [Mixtral-8x7B-instruct](https://huggingface.co/mistralai/Mixtral-8x7B-Instruct-v0.1).
- [Mixtral 8x22B](https://huggingface.co/mistral-community/Mixtral-8x22B-v0.1).
- [CodeGemma 7B IT](https://huggingface.co/google/codegemma-7b-it).
- [CodeGemma 2B](https://huggingface.co/google/codegemma-2b) or [7B](https://huggingface.co/google/codegemma-7b).

### Recommended serving architectures

For Mistral, you should use one of the following architectures:

- [vLLM](https://docs.vllm.ai/en/stable/)
- [TensorRT-LLM](https://docs.mistral.ai/deployment/self-deployment/overview/)
- [Ollama and litellm](litellm_proxy_setup.md)

## Step 2: Install the GitLab AI Gateway

### Install by using Docker

Prerequisites:

- You must [install Docker](https://docs.docker.com/engine/install/#server).
- Use a valid hostname accessible within your network. Do not use `localhost`.

The GitLab AI Gateway Docker image contains all necessary code and dependencies in a single container.

Find the GitLab official Docker image at:

- [AI Gateway Docker image on Container Registry](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/).
- [Release process for self-hosted AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/release.md).

WARNING:
Docker for Windows is not officially supported. There are known issues with volume
permissions, and potentially other unknown issues. If you are trying to run on Docker
for Windows, see the [getting help page](https://about.gitlab.com/get-help/) for links
to community resources (such as IRC or forums) to seek help from other users.

#### Set up the volumes location

Create a directory where the logs will reside on the Docker host. It can be under your user's home directory (for example
`~/gitlab-agw`), or in a directory like `/srv/gitlab-agw`. To create that directory, run:

```shell
sudo mkdir -p /srv/gitlab-agw
```

If you're running Docker with a user other than `root`, ensure appropriate
permissions have been granted to that directory.

#### Find the AI Gateway release

In a production environment, you should set your deployment to a specific
GitLab AI Gateway release. Find the release to use in [GitLab AI Gateway releases](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/releases), for example:

```shell
docker run -p 5000:500 -e AIGW_CUSTOM_MODELS__ENABLED=true registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:v1.4.0`
```

To set your deployment to the latest stable release, use the `latest` tag to run the latest stable release:

```shell
docker run -p 5000:500 -e AIGW_CUSTOM_MODELS__ENABLED=true registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:latest`
```

NOTE:
We do not yet support multi-arch image, only `linux/amd64`. If you try to run this on Apple chip, adding `--platform linux/amd64` to the `docker run` command will help.

### Install by using Docker Engine

1. For the AI Gateway to access the API, it must know where the GitLab instance
   is located. To do this, set the environment variables `AIGW_GITLAB_URL` and
   `AIGW_GITLAB_API_URL`:

   ```shell
   AIGW_GITLAB_URL=https://<your_gitlab_domain>
   AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/
   ```

1. For the GitLab instance to know where AI Gateway is located so it can access
   the gateway, set the environment variable `AI_GATEWAY_URL` inside your GitLab
   instance environment variables:

   ```shell
   AI_GATEWAY_URL=https://<your_ai_gitlab_domain>
   ```

1. After you've set up the environment variables, run the image. For example:

   ```shell
   docker run -p 5000:500 -e AIGW_CUSTOM_MODELS__ENABLED=true registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:latest
   ```

   This command downloads and starts a AI Gateway container, and
   [publishes ports](https://docs.docker.com/network/#published-ports) needed to
   access SSH, HTTP and HTTPS.

1. Track the initialization process:

   ```shell
   sudo docker logs -f gitlab-aigw
   ```

After starting the container, visit `gitlab-aigw.example.com`. It might take
a while before the Docker container starts to respond to queries.

## Upgrade the AI Gateway

To upgrade the AI Gateway, download the newest Docker image tag.

1. Stop the running container:

   ```shell
   sudo docker stop gitlab-aigw
   ```

1. Remove the existing container:

   ```shell
   sudo docker rm gitlab-aigw
   ```

1. Pull the new image:

   ```shell
   docker run -p 5000:500 -e AIGW_CUSTOM_MODELS__ENABLED=true registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:latest
   ```

1. Ensure that the environment variables are all set correctly

## Alternative installation methods

For information on alternative ways to install the AI Gateway, see [issue 463773](https://gitlab.com/gitlab-org/gitlab/-/issues/463773).
