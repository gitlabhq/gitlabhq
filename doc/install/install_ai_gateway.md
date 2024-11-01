---
stage: AI-Powered
group: AI Framework
description: Set up your self-hosted model GitLab AI Gateway
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Install the GitLab AI Gateway

The [AI gateway](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/ai_gateway/) is a standalone service that gives access to AI-powered GitLab Duo features.

## Install using Docker

Prerequisites:

- Install a Docker container engine, such as [Docker](https://docs.docker.com/engine/install/#server).
- Use a valid hostname accessible within your network. Do not use `localhost`.

The GitLab AI Gateway Docker image contains all necessary code and dependencies
in a single container.

The Docker image for the AI Gateway is around 340 MB (compressed) for the `linux/amd64` architecture and requires a minimum of 512 MB of RAM to operate. A GPU is not needed for the GitLab AI Gateway. To ensure better performance, especially under heavy usage, consider allocating more disk space, memory, and resources than the minimum requirements. Higher RAM and disk capacity can enhance the AI Gateway's efficiency during peak loads.

### Find the AI Gateway release

Find the GitLab official Docker image at:

- [AI Gateway Docker image on Container Registry](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/).
- [AI Gateway Docker image on DockerHub](https://hub.docker.com/repository/docker/gitlab/model-gateway/tags).
- [Release process for self-hosted AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/main/docs/release.md).

Use the image tag that corresponds to your GitLab version. For example, if the
GitLab version is `v17.5.0`, use `self-hosted-v17.5.0-ee` tag.

### Start a container from the image

1. For Docker images with version `self-hosted-17.4.0-ee` and later, run the following:

   ```shell
   docker run -p 5052:5052 \
    -e AIGW_GITLAB_URL=<your_gitlab_instance> \
    -e AIGW_GITLAB_API_URL=https://<your_gitlab_domain>/api/v4/ \
    <image>
   ```

   From the container host, accessing `http://localhost:5052/docs` should open the AI Gateway API documentation.

1. Ensure that port `5052` is forwarded to the container from the host and is included in the `AI_GATEWAY_URL` environment variable.

If you encounter issues loading the PEM file, resulting in errors like `JWKError`, you may need to resolve an SSL certificate error.

To fix this, set the appropriate certificate bundle path in the Docker container by using the following environment variables:

- `SSL_CERT_FILE=/path/to/ca-bundle.pem`
- `REQUESTS_CA_BUNDLE=/path/to/ca-bundle.pem`

Replace `/path/to/ca-bundle.pem` with the actual path to your certificate bundle.

### Additional Configuration

If you encounter authentication issues during health checks, bypass the authentication temporarily by setting the following environment variable:

```shell
-e AIGW_AUTH__BYPASS_EXTERNAL=true
```

This can be helpful for troubleshooting, but you should disable this after fixing the issues.

## Install using the AI Gateway Helm chart

Prerequisites:

- You must have a:
  - Domain you own, that you can add a DNS record to.
  - Kubernetes cluster.
  - Working installation of `kubectl`.
  - Working installation of Helm, version v3.11.0 or later.

For more information, see [Test the GitLab chart on GKE or EKS](https://docs.gitlab.com/charts/quickstart/index.html).

### Add the AI Gateway Helm repository

Add the AI Gateway Helm repository to Helm’s configuration:

```shell
helm repo add ai-gateway \
https://gitlab.com/api/v4/projects/gitlab-org%2fcharts%2fai-gateway-helm-chart/packages/helm/devel
```

### Install the AI Gateway

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

You might need to set up your own **Ingress Controller** for the AI Gateway if your existing `nginx` Ingress controller does not serve services in a different namespace. Make sure Ingress is set up correctly for multi-namespace deployments.

For versions of the `ai-gateway` Helm chart, use `helm search repo ai-gateway --versions` to find the appropriate chart version.

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

## Health Check and Debugging

To debug issues with your self-hosted Duo installation, run the following command:

```shell
sudo gitlab-rake gitlab:duo:verify_self_hosted_setup
```

Ensure that:

- The environment variable `AI_GATEWAY_URL` is correctly set.
- Duo access has been explicitly enabled for the root user through `/admin/code_suggestions`.

If access issues persist, check that authentication is correctly configured, and that the health check passes.

In case of persistent issues, the error message may suggest bypassing authentication with `AIGW_AUTH__BYPASS_EXTERNAL=true`, but only do this for troubleshooting.
