---
stage: AI-Powered
group: Custom Models
description: Set up your self-hosted model infrastructure
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Set up your self-hosted model infrastructure

DETAILS:
**Tier:** For a limited time, Ultimate. On October 17, 2024, Ultimate with [GitLab Duo Enterprise](https://about.gitlab.com/gitlab-duo/#pricing).
**Offering:** Self-managed
**Status:** Beta

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/12972) in GitLab 17.1 [with a flag](../../administration/feature_flags.md) named `ai_custom_model`. Disabled by default.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

By self-hosting the model, AI Gateway, and GitLab instance, there are no calls to
external architecture, ensuring maximum levels of security.

To set up your self-hosted model infrastructure:

1. Install the large language model (LLM) serving infrastructure.
1. Configure your GitLab instance.
1. Install the GitLab AI Gateway.

## Install large language model serving infrastructure

Install one of the following GitLab-approved LLM models:

| Model family | Model                                                                              | Code completion | Code generation | GitLab Duo Chat |
|--------------|------------------------------------------------------------------------------------|-----------------|-----------------|---------|
| Mistral      | [Codestral 22B](https://huggingface.co/mistralai/Codestral-22B-v0.1) (see [setup instructions](litellm_proxy_setup.md#example-setup-for-codestral-with-ollama))                                         | **{check-circle}** Yes               | **{check-circle}** Yes               | **{dotted-circle}** No        |
| Mistral      | [Mistral 7B](https://huggingface.co/mistralai/Mistral-7B-v0.1)                     | **{dotted-circle}** No                | **{check-circle}** Yes               | **{check-circle}** Yes        |
| Mistral      | [Mixtral 8x22B](https://huggingface.co/mistral-community/Mixtral-8x22B-v0.1)       | **{dotted-circle}** No                | **{check-circle}** Yes               | **{check-circle}** Yes        |
| Mistral      | [Mixtral 8x7B](https://huggingface.co/mistralai/Mixtral-8x7B-Instruct-v0.1)        | **{dotted-circle}** No                | **{check-circle}** Yes               | **{check-circle}** Yes        |
| Mistral      | [Mistral 7B Text](https://huggingface.co/mistralai/Mistral-7B-v0.3)                     | **{check-circle}** Yes                | **{dotted-circle}** No               |**{dotted-circle}** No        |
| Mistral      | [Mixtral 8x22B Text](https://huggingface.co/mistralai/Mixtral-8x22B-v0.1)       | **{check-circle}** Yes                | **{dotted-circle}** No               | **{dotted-circle}** No        |
| Mistral      | [Mixtral 8x7B Text](https://huggingface.co/mistralai/Mixtral-8x7B-v0.1)        | **{check-circle}** Yes                | **{dotted-circle}** No               | **{dotted-circle}** No        |
| Claude 3     | [Claude 3.5 Sonnet](https://www.anthropic.com/news/claude-3-5-sonnet)        | **{check-circle}** Yes                | **{check-circle}** Yes               | **{check-circle}** Yes        |

The following models are under evaluation, and support is limited:

| Model family  | Model                                                                              | Code completion | Code generation | GitLab Duo Chat |
|---------------|---------------------------------------------------------------------|-----------------|-----------------|---------|
| CodeGemma     | [CodeGemma 2b](https://huggingface.co/google/codegemma-2b)                         | **{check-circle}** Yes               | **{dotted-circle}** No               | **{dotted-circle}** No        |
| CodeGemma     | [CodeGemma 7b-it](https://huggingface.co/google/codegemma-7b-it) (Instruction)     | **{dotted-circle}** No                | **{check-circle}** Yes               | **{dotted-circle}** No        |
| CodeGemma     | [CodeGemma 7b-code](https://huggingface.co/google/codegemma-7b) (Code)             | **{check-circle}** Yes               | **{dotted-circle}** No               | **{dotted-circle}** No        |
| CodeLlama     | [Code-Llama 13b-code](https://huggingface.co/meta-llama/CodeLlama-13b-hf)          | **{check-circle}** Yes               | **{dotted-circle}** No               | **{dotted-circle}** No        |
| CodeLlama     | [Code-Llama 13b](https://huggingface.co/meta-llama/CodeLlama-13b-Instruct-hf)      | **{dotted-circle}** No                | **{check-circle}** Yes               | **{dotted-circle}** No        |
| DeepSeekCoder | [DeepSeek Coder 33b Instruct](https://huggingface.co/deepseek-ai/deepseek-coder-33b-instruct)        | **{check-circle}** Yes                | **{check-circle}** Yes               | **{dotted-circle}** No        |
| DeepSeekCoder | [DeepSeek Coder 33b Base](https://huggingface.co/deepseek-ai/deepseek-coder-33b-base)        | **{check-circle}** Yes                | **{dotted-circle}** No               | **{dotted-circle}** No        |

### Use a serving architecture

To host your models, you should use:

- For non-cloud on-premise deployments, [vLLM](https://docs.vllm.ai/en/stable/).
- For cloud deployments, AWS Bedrock as a cloud provider.

## Configure your GitLab instance

Prerequisites:

- Upgrade to the latest version of GitLab.

1. The GitLab instance must be able to access the AI Gateway.

   1. Where your GitLab instance is installed, update the `/etc/gitlab/gitlab.rb` file.

      ```shell
      sudo vim /etc/gitlab/gitlab.rb
      ```

   1. Add and save the following environment variables.

      ```.rb
      gitlab_rails['env'] = {
      'GITLAB_LICENSE_MODE' => 'production',
      'CUSTOMER_PORTAL_URL' => 'https://customers.gitlab.com',
      'AI_GATEWAY_URL' => '<path_to_your_ai_gateway>:<port>'
      }
      ```

   1. Run reconfigure:

      ```shell
      sudo gitlab-ctl reconfigure
      ```

## Install the GitLab AI Gateway

### Install by using Docker

Prerequisites:

- Install a Docker container engine, such as [Docker](https://docs.docker.com/engine/install/#server).
- Use a valid hostname accessible within your network. Do not use `localhost`.

The GitLab AI Gateway Docker image contains all necessary code and dependencies
in a single container.

#### Find the AI Gateway release

Find the GitLab official Docker image at:

- [AI Gateway Docker image on Container Registry](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/).
- [AI Gateway Docker image on DockerHub](https://hub.docker.com/repository/docker/gitlab/model-gateway/tags).
- [Release process for self-hosted AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/release.md).

Use the image tag that corresponds to your GitLab version. For example, if the
GitLab version is `v17.5.0`, use `self-hosted-v17.5.0-ee` tag.

#### Set up the volumes location

Create a directory where the logs will reside on the Docker host. It can be under
your user's home directory (for example `~/gitlab-agw`), or in a directory like
`/srv/gitlab-agw`. To create that directory, run:

```shell
sudo mkdir -p /srv/gitlab-agw
```

If you're running Docker with a user other than `root`, ensure appropriate
permissions have been granted to that directory.

#### Start a container from the image

For Docker images with version `self-hosted-17.4.0-ee` and later, run the following:

```shell
docker run -p 5052:5052 \
 -e AIGW_GITLAB_URL=<your_gitlab_instance> \
 -e AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/ \
 <image>
```

From the container host, accessing `http://localhost:5052/docs`
should open the AI Gateway API documentation.

### Install by using the AI Gateway Helm chart

Prerequisites:

- You must have a:
  - Domain you own, that you can add a DNS record to.
  - Kubernetes cluster.
  - Working installation of `kubectl`.
  - Working installation of Helm, version v3.11.0 or later.

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
   is located. To do this, set the `gitlab.url` and `gitlab.apiUrl` together with
   the `ingress.hosts` and `ingress.tls` values as follows:

   ```shell
   helm repo add ai-gateway \
     https://gitlab.com/api/v4/projects/gitlab-org%2fcharts%2fai-gateway-helm-chart/packages/helm/devel
   helm repo update

   helm upgrade --install ai-gateway \
     ai-gateway/ai-gateway \
     --version 0.1.1 \
     --namespace=ai-gateway \
     --set="image.tag=<ai-gateway-image>" \
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

This step can take will take a few seconds in order for all resources to be allocated
and the AI Gateway to start.

Wait for your pods to get up and running:

```shell
kubectl wait pod \
  --all \
  --for=condition=Ready \
  --namespace=ai-gateway \
  --timeout=300s
```

When your pods are up and running, you can set up your IP ingresses and DNS records.

#### Configure the GitLab instance

[Configure the GitLab instance](#configure-your-gitlab-instance).

With those steps completed, your Helm chart installation is complete.

## Upgrade the AI Gateway Docker image

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

1. Ensure that the environment variables are all set correctly.

## Alternative installation methods

For information on alternative ways to install the AI Gateway, see
[issue 463773](https://gitlab.com/gitlab-org/gitlab/-/issues/463773).

## Troubleshooting

First, run the [debugging scripts](troubleshooting.md#use-debugging-scripts) to
verify your self-hosted model setup.

For more information on other actions to take, see the
[troubleshooting documentation](troubleshooting.md).
