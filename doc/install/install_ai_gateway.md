---
stage: AI-Powered
group: AI Framework
description: Set up your self-hosted model GitLab AI Gateway
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab AI Gateway

The [AI gateway](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/ai_gateway/) is a standalone service that gives access to AI-powered GitLab Duo features.

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
