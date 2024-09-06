---
stage: AI-Powered
group: Custom Models
description: Setup your self-hosted model deployment infrastructure
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
1. Configure your GitLab instance.
1. Install the GitLab AI Gateway.

- [Installation video guide](https://youtu.be/UNmD9-sgUvw)
- [Installation video guide (French version)](https://www.youtube.com/watch?v=aU5vnzO-MSM)

## Step 1: Install LLM serving infrastructure

Install one of the following GitLab-approved LLM models:

| Model                                                                              | Code completion | Code generation | GitLab Duo Chat |
|------------------------------------------------------------------------------------|-----------------|-----------------|---------|
| [CodeGemma 2b](https://huggingface.co/google/codegemma-2b)                         | **{check-circle}** Yes               | **{dotted-circle}** No               | **{dotted-circle}** No        |
| [CodeGemma 7b-it](https://huggingface.co/google/codegemma-7b-it) (Instruction)     | **{dotted-circle}** No                | **{check-circle}** Yes               | **{dotted-circle}** No        |
| [CodeGemma 7b-code](https://huggingface.co/google/codegemma-7b) (Code)             | **{check-circle}** Yes               | **{dotted-circle}** No               | **{dotted-circle}** No        |
| [Code-Llama 13b-code](https://huggingface.co/meta-llama/CodeLlama-13b-hf)          | **{check-circle}** Yes               | **{dotted-circle}** No               | **{dotted-circle}** No        |
| [Code-Llama 13b](https://huggingface.co/meta-llama/CodeLlama-13b-Instruct-hf)      | **{dotted-circle}** No                | **{check-circle}** Yes               | **{dotted-circle}** No        |
| [Codestral 22B](https://huggingface.co/mistralai/Codestral-22B-v0.1) (see [setup instructions](litellm_proxy_setup.md#example-setup-for-codestral-with-ollama))                                         | **{check-circle}** Yes               | **{check-circle}** Yes               | **{dotted-circle}** No        |
| [Mistral 7B](https://huggingface.co/mistralai/Mistral-7B-v0.1)                     | **{dotted-circle}** No                | **{check-circle}** Yes               | **{check-circle}** Yes        |
| [Mixtral 8x22B](https://huggingface.co/mistral-community/Mixtral-8x22B-v0.1)       | **{dotted-circle}** No                | **{check-circle}** Yes               | **{check-circle}** Yes        |
| [Mixtral 8x7B](https://huggingface.co/mistralai/Mixtral-8x7B-Instruct-v0.1)        | **{dotted-circle}** No                | **{check-circle}** Yes               | **{check-circle}** Yes        |

### Recommended serving architectures

You should use one of the following architectures:

- [vLLM](https://docs.vllm.ai/en/stable/)
- [TensorRT-LLM](https://docs.mistral.ai/deployment/self-deployment/overview/)
- [Ollama and litellm](litellm_proxy_setup.md)

#### Litellm config examples for quickly getting started with Ollama

```yaml
model_list:
  - model_name: mistral
    litellm_params:
      model: ollama/mistral:latest
      api_base: YOUR_HOSTING_SERVER
  - model_name: mixtral
    litellm_params:
      model: ollama/mixtral:latest
      api_base: YOUR_HOSTING_SERVER
  - model_name: codegemma
    litellm_params:
      model: ollama/codegemma
      api_base: YOUR_HOSTING_SERVER
  - model_name: codestral
    litellm_params:
      model: ollama/codestral
      api_base: YOUR_HOSTING_SERVER
  - model_name: codellama
    litellm_params:
      model: ollama/codellama:13b
      api_base: YOUR_HOSTING_SERVER
  - model_name: codellama_13b_code
    litellm_params:
      model: ollama/codellama:code
      api_base: YOUR_HOSTING_SERVER
  - model_name: deepseekcoder
    litellm_params:
      model: ollama/deepseekcoder
      api_base: YOUR_HOSTING_SERVER
  - model_name: mixtral_8x22b
    litellm_params:
      model: ollama/mixtral:8x22b
      api_base: YOUR_HOSTING_SERVER
  - model_name: codegemma_2b
    litellm_params:
      model: ollama/codegemma:2b
      api_base: YOUR_HOSTING_SERVER
  - model_name: codegemma_7b
    litellm_params:
      model: ollama/codegemma:code
      api_base: YOUR_HOSTING_SERVER
```

## Step 2: Configure your GitLab instance

1. For the GitLab instance to know where AI Gateway is located so it can access
   the gateway, set the environment variable `AI_GATEWAY_URL` inside your GitLab
   instance environment variables:

   ```shell
   AI_GATEWAY_URL=https://<your_ai_gitlab_domain>
   CLOUD_CONNECTOR_SELF_SIGN_TOKENS=1
   ```

1. Where your GitLab instance is installed, [run the following Rake task](../../raketasks/index.md) to activate GitLab Duo features:

   ```shell
   sudo gitlab-rake gitlab:duo:enable_feature_flags
   ```

1. [Start a GitLab Rails console](../feature_flags.md#start-the-gitlab-rails-console):

   ```shell
   sudo gitlab-rails console
   ```

   In the console, enable the `ai_custom_model` feature flag:

   ```shell
   Feature.enable(:ai_custom_model)
   ```

   Exit the Rails console.

## Step 3: Install the GitLab AI Gateway

### Install by using Docker

Prerequisites:

- Install a Docker container engine, such as [Docker](https://docs.docker.com/engine/install/#server).
- Use a valid hostname accessible within your network. Do not use `localhost`.

The GitLab AI Gateway Docker image contains all necessary code and dependencies in a single container.

#### Find the AI Gateway release

Find the GitLab official Docker image at:

- [AI Gateway Docker image on Container Registry](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/).
- [AI Gateway Docker image on DockerHub](https://hub.docker.com/repository/docker/gitlab/model-gateway/tags).
- [Release process for self-hosted AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/release.md).

Use the image tag that corresponds to your GitLab version. For example, if the GitLab version is `v17.4.0`, use `self-hosted-v17.4.0-ee` tag.
For version `v17.3.0-ee`, use image tag `gitlab-v17.3.0`.

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

#### Optional: Download documentation index

NOTE:
This only applies to AI Gateway image tag `gitlab-17.3.0-ee` and earlier. For images with tag `self-hosted-v17.4.0-ee` and later, documentation search is embedded into the Docker image.

To improve results when asking GitLab Duo Chat questions about GitLab, you can
index GitLab documentation and provide it as a file to the AI Gateway.

To index the documentation in your local installation,run:

```shell
pip install requests langchain langchain_text_splitters
python3 scripts/custom_models/create_index.py -o <path_to_created_index/docs.db>
```

This creates a file `docs.db` at the specified path.

You can also create an index for a specific GitLab version:

```shell
python3 scripts/custom_models/create_index.py --version_tag="{gitlab-version}"
```

#### Start a container from the image

For Docker images with version `self-hosted-17.4.0-ee` and later, run the following:

```shell
docker run -e AIGW_GITLAB_URL=<your_gitlab_instance> <image>
```

For Docker images with version `gitlab-17.3.0-ee` and `gitlab-17.2.0`:

```shell
docker run -e AIGW_CUSTOM_MODELS__ENABLED=true \
   -v path/to/created/index/docs.db:/app/tmp/docs.db \
   -e AIGW_FASTAPI__OPENAPI_URL="/openapi.json" \
   -e AIGW_AUTH__BYPASS_EXTERNAL=true \
   -e AIGW_FASTAPI__DOCS_URL="/docs"\
   -e AIGW_FASTAPI__API_PORT=5052 \
   <image>
```

The arguments `AIGW_FASTAPI__OPENAPI_URL` and `AIGW_FASTAPI__DOCS_URL` are not
mandatory, but are useful for debugging. From the host, accessing `http://localhost:5052/docs`
should open the AI Gateway API documentation.

### Install by using Docker Engine

1. For the AI Gateway to access the API, it must know where the GitLab instance
   is located. To do this, set the environment variables `AIGW_GITLAB_URL` and
   `AIGW_GITLAB_API_URL`:

   ```shell
   AIGW_GITLAB_URL=https://<your_gitlab_domain>
   AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/
   ```

1. [Configure the GitLab instance](#step-2-configure-your-gitlab-instance).

1. After you've set up the environment variables, [run the image](#start-a-container-from-the-image).

1. Track the initialization process:

   ```shell
   sudo docker logs -f gitlab-aigw
   ```

After starting the container, visit `gitlab-aigw.example.com`. It might take
a while before the Docker container starts to respond to queries.

### Upgrade the AI Gateway Docker image

To upgrade the AI Gateway, download the newest Docker image tag.

1. Stop the running container:

   ```shell
   sudo docker stop gitlab-aigw
   ```

1. Remove the existing container:

   ```shell
   sudo docker rm gitlab-aigw
   ```

1. Pull and [run the new image](#start-a-container-from-the-image).

1. Ensure that the environment variables are all set correctly

### Install by using the AI Gateway Helm chart

#### Prerequisites

To complete this guide, you must have the following:

- A domain you own, that you can add a DNS record to.
- A Kubernetes cluster.
- A working installation of `kubectl`.
- A working installation of Helm, version v3.11.0 or later.

For more information, see [Test the GitLab chart on GKE or EKS](https://docs.gitlab.com/charts/quickstart/index.html).

#### Add the AI Gateway Helm repository

Add the AI Gateway Helm repository to Helm’s configuration:

```shell
helm repo add ai-gateway \
https://gitlab.com/api/v4/projects/gitlab-org%2fcharts%2fai-gateway-helm-chart/packages/helm/devel
```

#### Install the AI Gateway

1. Create the `ai-gateway` namespace:

   ```shell
   kubectl create namespace ai-gateway
   ```

1. Generate the certificate for the domain where you plan to expose the AI Gateway.
1. Create the TLS secret in the previously created namespace:

   ```shell
   kubectl -n ai-gateway create secret tls ai-gateway-tls --cert="<path_to_cert>" --key="<path_to_cert_key>"
   ```

1. For the AI Gateway to access the API, it must know where the GitLab instance
is located. To do this, set the `gitlab.url` and
`gitlab.apiUrl` together with the `ingress.hosts` and `ingress.tls` values as follows:

   ```shell
   helm repo add ai-gateway \
     https://gitlab.com/api/v4/projects/gitlab-org%2fcharts%2fai-gateway-helm-chart/packages/helm/devel
   helm repo update

   helm upgrade --install ai-gateway \
     ai-gateway/ai-gateway \
     --version 0.1.1 \
     --namespace=ai-gateway \
     --set="gitlab.url=https://<your_gitlab_domain>" \
     --set="gitlab.apiUrl=https://<your_gitlab_domain>/api/v4/" \
     --set "ingress.enabled=true" \
     --set "ingress.hosts[0].host=<your_gateway_domain>" \
     --set "ingress.hosts[0].paths[0].path=/" \
     --set "ingress.hosts[0].paths[0].pathType=ImplementationSpecific" \
     --set "ingress.tls[0].secretName=ai-gateway-tls" \
     --set "ingress.tls[0].hosts[0]=<your_gateway_domain>" \
     --set="ingress.className=nginx" \
     --timeout=300s --wait --wait-for-jobs
   ```

This step can take will take a few seconds in order for all resources to be allocated and the AI Gateway to start.

Wait for your pods to get up and running:

```shell
kubectl wait pod \
  --all \
  --for=condition=Ready \
  --namespace=ai-gateway \
  --timeout=300s
```

When it's done, you can proceed with setting up your IP ingresses and DNS records.

#### Installation steps in the GitLab instance

[Configure the GitLab instance](#step-2-configure-your-gitlab-instance).

With those steps completed, your Helm chart installation is complete.

## Alternative installation methods

For information on alternative ways to install the AI Gateway, see [issue 463773](https://gitlab.com/gitlab-org/gitlab/-/issues/463773).

## Troubleshooting

First, run the [debugging scripts](troubleshooting.md#use-debugging-scripts) to verify your self-hosted model setup.

For more information on other actions to take, see the [troubleshooting documentation](troubleshooting.md).

### The image's platform does not match the host

When [finding the AI Gateway release](#find-the-ai-gateway-release), you might get an error that states `The requested image’s platform (linux/amd64) does not match the detected host`.

To work around this error, add `--platform linux/amd64` to the `docker run` command:

```shell
docker run --platform linux/amd64 -e AIGW_GITLAB_URL=<your-gitlab-endpoint> <image>
```
