---
stage: AI-Powered
group: Custom Models
description: Setup your Self-Hosted Model Deployment infrastructure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Set up your self-hosted model deployment infrastructure

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

By self-hosting the model, AI gateway, and GitLab instance, there are no calls to external architecture, ensuring maximum levels of security.

To set up your self-hosted model deployment infrastructure:

1. Install the large language model (LLM) serving infrastructure.
1. Install the GitLab AI Gateway.

## Step 1: Install LLM serving infrastructure

Install one of the following GitLab-approved LLM models:

- [Mistral-7B-v0.1](https://huggingface.co/mistralai/Mistral-7B-v0.1).
- [Mixtral-8x7B-instruct](https://huggingface.co/mistralai/Mixtral-8x7B-Instruct-v0.1).
- [Mixtral 8x22B](https://huggingface.co/mistral-community/Mixtral-8x22B-v0.1).
- [CodeGemma 7B IT](https://huggingface.co/google/codegemma-7b-it).
- [CodeGemma 2B](https://huggingface.co/google/codegemma-2b).

### Recommended serving architectures

For Mistral, you should use one of the following architectures:

- [vLLM](https://docs.vllm.ai/en/stable/)
- [TensorRT-LLM](https://docs.mistral.ai/deployment/self-deployment/overview/)

## Step 2: Install the GitLab AI Gateway

### Install using Docker

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

#### Find the AI Gateway Release

In a production environment, you should pin your deployment to a specific
GitLab AI Gateway release. Find the release to use in [GitLab AI Gateway Releases](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/releases), for example: `7d5f58e1` where `7d5f58e1` is the AI Gateway released version.

To pin your deployment to the latest stable release, use the `latest` tag to run the latest stable release:

```shell
docker run -p 5000:500 registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:latest`
```

NOTE:
We do not yet support multi-arch image, only `linux/amd64`. If you try to run this on Apple chip, adding `--platform linux/amd64` to the `docker run` command will help.

#### Prerequisites

To use the GitLab Docker images:

- You must [install Docker](https://docs.docker.com/engine/install/#server).
- You should use a valid hostname accessible within your network. Do not use `localhost`.

#### Install using Docker Engine

1. For the AI Gateway to know where the GitLab instance is located so it can access the API, set the environment variable `AIGW_GITLAB_API_URL`.

   For example, run:

   ```shell
   AIGW_GITLAB_API_URL=https://YOUR_GITLAB_DOMAIN/api/v4/
   ```

1. For the GitLab instance to know where AI Gateway is located so it can access the gateway, set the environment variable `AI_GATEWAY_URL`
   inside your GitLab instance environment variables.

   For example, run:

   ```shell
   AI_GATEWAY_URL=https://YOUR_AI_GATEWAY_DOMAIN
   ```

1. After you've set up the environment variables, run the image. For example:

   ```shell
   docker run -p 5000:500 registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:latest
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

#### Upgrade

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
   docker run -p 5000:500 registry.gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/model-gateway:latest
   ```

1. Ensure that the environment variables are all set correctly

### Alternative installation methods

For information on alternative ways to install the AI Gateway, see [issue 463773](https://gitlab.com/gitlab-org/gitlab/-/issues/463773).
